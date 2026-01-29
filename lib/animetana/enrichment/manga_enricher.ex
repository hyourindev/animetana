defmodule Animetana.Enrichment.MangaEnricher do
  @moduledoc """
  Enriches manga entries with AI-generated content.
  Batches 10 manga per API call to reduce costs.
  """

  require Logger
  import Ecto.Query
  alias Animetana.Enrichment.Client
  alias Animetana.Repo

  @concurrency 25
  @batch_size 5

  @doc """
  Enriches manga entries in batches.

  ## Options
    - `:limit` - Maximum entries to process (default: all)
    - `:concurrency` - Parallel requests (default: 25)
    - `:batch_size` - Entries per API call (default: 10)
  """
  def run(opts \\ []) do
    limit = Keyword.get(opts, :limit, nil)
    concurrency = Keyword.get(opts, :concurrency, @concurrency)
    batch_size = Keyword.get(opts, :batch_size, @batch_size)

    Logger.info("[MangaEnricher] Starting with #{concurrency} workers, #{batch_size} per batch...")

    entries = get_entries(limit)
    total = length(entries)
    batches = Enum.chunk_every(entries, batch_size)
    batch_count = length(batches)

    Logger.info("[MangaEnricher] Found #{total} entries (#{batch_count} batches)")

    if total == 0 do
      {:ok, 0}
    else
      process_parallel(batches, batch_count, concurrency)
    end
  end

  defp get_entries(limit) do
    query =
      from(m in "manga",
        prefix: "contents",
        where: is_nil(m.deleted_at) and fragment("COALESCE(?, 0) < 7", m.enrichment_status),
        select: %{
          id: m.id,
          title_en: m.title_en,
          title_ja: m.title_ja,
          title_romaji: m.title_romaji,
          synopsis_en: m.synopsis_en
        },
        order_by: [asc: m.id]
      )

    query = if limit, do: limit(query, ^limit), else: query
    Repo.all(query)
  end

  defp process_parallel(batches, batch_count, concurrency) do
    counter = :counters.new(1, [:atomics])

    results =
      batches
      |> Task.async_stream(
        fn batch ->
          count = :counters.add(counter, 1, 1) && :counters.get(counter, 1)
          ids = Enum.map(batch, & &1.id) |> Enum.join(", ")
          Logger.info("[MangaEnricher] Batch #{count}/#{batch_count} (ids: #{ids})")
          enrich_batch(batch)
        end,
        max_concurrency: concurrency,
        timeout: 180_000,
        on_timeout: :kill_task
      )
      |> Enum.flat_map(fn
        {:ok, results} -> results
        {:exit, :timeout} -> [{:error, :timeout}]
      end)

    success_count = Enum.count(results, &match?({:ok, _}, &1))
    error_count = length(results) - success_count

    Logger.info("[MangaEnricher] Done: #{success_count} ok, #{error_count} errors")

    {:ok, success_count}
  end

  defp enrich_batch(entries) do
    prompt = build_batch_prompt(entries)
    messages = [
      %{"role" => "system", "content" => system_prompt()},
      %{"role" => "user", "content" => prompt}
    ]

    case Client.chat_completion(messages) do
      {:ok, content} ->
        case parse_batch_response(content, entries) do
          {:ok, results} ->
            Enum.map(results, fn {id, data} ->
              update_entry(id, data)
              {:ok, id}
            end)

          {:error, reason} ->
            Logger.warning("[MangaEnricher] Parse failed: #{inspect(reason)}")
            Enum.map(entries, fn e ->
              mark_error(e.id, "Parse: #{inspect(reason)}")
              {:error, reason}
            end)
        end

      {:error, reason} ->
        Logger.warning("[MangaEnricher] API failed: #{inspect(reason)}")
        Enum.map(entries, fn e ->
          mark_error(e.id, "API: #{inspect(reason)}")
          {:error, reason}
        end)
    end
  end

  defp system_prompt do
    """
    You are a manga database assistant. You MUST respond with ONLY a valid JSON array.
    NO markdown, NO explanation, NO text outside the JSON.

    IMPORTANT: synopsis_ja MUST always be in Japanese (日本語), even for Korean/Chinese manga.

    Example response format:
    [{"id":123,"title_en":"Title","title_ja":"タイトル","title_romaji":"Taitoru","synopsis_en":"English synopsis.","synopsis_ja":"日本語のあらすじ。"}]
    """
  end

  defp build_batch_prompt(entries) do
    manga_json =
      entries
      |> Enum.map(fn e ->
        %{
          id: e.id,
          title: e.title_en || e.title_romaji || "",
          title_ja: e.title_ja || "",
          synopsis: String.slice(e.synopsis_en || "", 0, 300)
        }
      end)
      |> Jason.encode!()

    """
    Input manga data:
    #{manga_json}

    For each manga, return a JSON array where each object has:
    - "id": same as input
    - "title_en": official English title
    - "title_ja": Japanese title (keep if exists)
    - "title_romaji": romanized title
    - "synopsis_en": improved English synopsis (1-2 sentences)
    - "synopsis_ja": Japanese translation (日本語 ONLY, not Korean/Chinese)

    Return ONLY the JSON array, nothing else.
    """
  end

  defp parse_batch_response(content, entries) do
    cleaned =
      content
      |> String.trim()
      |> String.replace(~r/^```json\n?/, "")
      |> String.replace(~r/\n?```$/, "")
      |> String.trim()

    entry_map = Map.new(entries, &{&1.id, &1})

    case Jason.decode(cleaned) do
      {:ok, list} when is_list(list) ->
        results =
          Enum.map(list, fn item ->
            id = item["id"]
            {id, %{
              title_en: item["title_en"],
              title_ja: item["title_ja"],
              title_romaji: item["title_romaji"],
              synopsis_en: item["synopsis_en"],
              synopsis_ja: item["synopsis_ja"],
              background_en: nil,
              background_ja: nil
            }}
          end)
          |> Enum.filter(fn {id, _} -> Map.has_key?(entry_map, id) end)

        {:ok, results}

      {:ok, _} ->
        {:error, :not_array}

      {:error, reason} ->
        {:error, {:json_parse, reason}}
    end
  end

  defp update_entry(id, data) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    from(m in "manga", prefix: "contents", where: m.id == ^id)
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
    from(m in "manga", prefix: "contents", where: m.id == ^id)
    |> Repo.update_all(set: [enrichment_error: error])
  end
end
