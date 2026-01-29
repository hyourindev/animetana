defmodule Animetana.Enrichment.AnimeEnricher do
  @moduledoc """
  Enriches anime entries with AI-generated content.
  Single API call per entry returns all fields as JSON.
  """

  require Logger
  import Ecto.Query
  alias Animetana.Enrichment.Client
  alias Animetana.Repo

  @concurrency 25

  @doc """
  Enriches anime entries.

  ## Options
    - `:limit` - Maximum entries to process (default: all)
    - `:concurrency` - Parallel requests (default: 100)
  """
  def run(opts \\ []) do
    limit = Keyword.get(opts, :limit, nil)
    concurrency = Keyword.get(opts, :concurrency, @concurrency)

    Logger.info("[AnimeEnricher] Starting with #{concurrency} parallel workers...")

    entries = get_entries(limit)
    total = length(entries)

    Logger.info("[AnimeEnricher] Found #{total} entries to enrich")

    if total == 0 do
      {:ok, 0}
    else
      process_parallel(entries, total, concurrency)
    end
  end

  defp get_entries(limit) do
    query =
      from(a in "anime",
        prefix: "contents",
        where: is_nil(a.deleted_at) and fragment("COALESCE(?, 0) < 7", a.enrichment_status),
        select: %{
          id: a.id,
          title_en: a.title_en,
          title_ja: a.title_ja,
          title_romaji: a.title_romaji,
          synopsis_en: a.synopsis_en,
          format: a.format,
          source: a.source,
          season_year: a.season_year
        },
        order_by: [asc: a.id]
      )

    query = if limit, do: limit(query, ^limit), else: query
    Repo.all(query)
  end

  defp process_parallel(entries, total, concurrency) do
    counter = :counters.new(1, [:atomics])

    results =
      entries
      |> Task.async_stream(
        fn entry ->
          count = :counters.add(counter, 1, 1) && :counters.get(counter, 1)
          Logger.info("[AnimeEnricher] Processing #{count}/#{total}: #{entry.title_en || entry.title_romaji}")
          enrich_entry(entry)
        end,
        max_concurrency: concurrency,
        timeout: 120_000,
        on_timeout: :kill_task
      )
      |> Enum.map(fn
        {:ok, result} -> result
        {:exit, :timeout} -> {:error, :timeout}
      end)

    success_count = Enum.count(results, &match?({:ok, _}, &1))
    error_count = total - success_count

    Logger.info("[AnimeEnricher] Done: #{success_count} ok, #{error_count} errors")

    {:ok, success_count}
  end

  defp enrich_entry(entry) do
    prompt = build_prompt(entry)
    messages = [
      %{"role" => "system", "content" => system_prompt()},
      %{"role" => "user", "content" => prompt}
    ]

    case Client.chat_completion(messages) do
      {:ok, content} ->
        case parse_response(content) do
          {:ok, data} ->
            update_entry(entry.id, data)
            {:ok, entry.id}

          {:error, reason} ->
            Logger.warning("[AnimeEnricher] Parse failed for #{entry.id}: #{inspect(reason)}")
            mark_error(entry.id, "Parse: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.warning("[AnimeEnricher] API failed for #{entry.id}: #{inspect(reason)}")
        mark_error(entry.id, "API: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp system_prompt do
    """
    You are an anime database enrichment assistant. Given anime information, generate enriched content in JSON format.

    Return ONLY valid JSON with these fields:
    {
      "title_en": "Official English title",
      "title_ja": "Japanese title in Japanese characters",
      "title_romaji": "Romanized Japanese title",
      "synopsis_en": "Improved/rewritten English synopsis (2-3 paragraphs)",
      "synopsis_ja": "Japanese translation of the synopsis",
      "background_en": "Production background info in English (studio history, staff, adaptation details)",
      "background_ja": "Japanese translation of the background"
    }

    Guidelines:
    - title_en: Official English title. If unknown, translate from Japanese.
    - title_ja: Original Japanese title in kanji/kana. Keep existing if provided.
    - title_romaji: Romanization of Japanese title (e.g., "Shingeki no Kyojin")
    - synopsis_en: Improve clarity, fix grammar, make it engaging. Keep similar length.
    - synopsis_ja: Natural Japanese translation, use appropriate keigo
    - background_en: Focus on production facts, studio, director, source material
    - background_ja: Formal Japanese suitable for encyclopedia

    Return ONLY the JSON object, no markdown, no explanation.
    """
  end

  defp build_prompt(entry) do
    """
    Anime: #{entry.title_en || entry.title_romaji || "Unknown"}
    Japanese Title: #{entry.title_ja || "N/A"}
    Format: #{entry.format || "Unknown"}
    Source: #{entry.source || "Unknown"}
    Year: #{entry.season_year || "Unknown"}

    Current Synopsis:
    #{entry.synopsis_en || "(No synopsis)"}

    Generate the enriched JSON:
    """
  end

  defp parse_response(content) do
    cleaned =
      content
      |> String.trim()
      |> String.replace(~r/^```json\n?/, "")
      |> String.replace(~r/\n?```$/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, data} when is_map(data) ->
        {:ok, %{
          title_en: data["title_en"],
          title_ja: data["title_ja"],
          title_romaji: data["title_romaji"],
          synopsis_en: data["synopsis_en"],
          synopsis_ja: data["synopsis_ja"],
          background_en: data["background_en"],
          background_ja: data["background_ja"]
        }}

      {:ok, _} ->
        {:error, :invalid_structure}

      {:error, reason} ->
        {:error, {:json_parse, reason}}
    end
  end

  defp update_entry(id, data) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    from(a in "anime", prefix: "contents", where: a.id == ^id)
    |> Repo.update_all(
      set: [
        title_en: data.title_en,
        title_ja: data.title_ja,
        title_romaji: data.title_romaji,
        synopsis_en: data.synopsis_en,
        synopsis_ja: data.synopsis_ja,
        background_en: data.background_en,
        background_ja: data.background_ja,
        enrichment_status: 7,
        enrichment_error: nil,
        enriched_at: now
      ]
    )
  end

  defp mark_error(id, error) do
    from(a in "anime", prefix: "contents", where: a.id == ^id)
    |> Repo.update_all(set: [enrichment_error: error])
  end
end
