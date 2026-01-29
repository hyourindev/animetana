defmodule Animetana.Enrichment.CharacterEnricher do
  @moduledoc """
  Enriches character entries with AI-generated content.
  Single API call per entry returns all fields as JSON.
  """

  require Logger
  import Ecto.Query
  alias Animetana.Enrichment.Client
  alias Animetana.Repo

  @concurrency 25

  @doc """
  Enriches character entries.

  ## Options
    - `:limit` - Maximum entries to process (default: all)
    - `:concurrency` - Parallel requests (default: 100)
  """
  def run(opts \\ []) do
    limit = Keyword.get(opts, :limit, nil)
    concurrency = Keyword.get(opts, :concurrency, @concurrency)

    Logger.info("[CharacterEnricher] Starting with #{concurrency} parallel workers...")

    entries = get_entries(limit)
    total = length(entries)

    Logger.info("[CharacterEnricher] Found #{total} entries to enrich")

    if total == 0 do
      {:ok, 0}
    else
      process_parallel(entries, total, concurrency)
    end
  end

  defp get_entries(limit) do
    query =
      from(c in "characters",
        prefix: "contents",
        where: is_nil(c.deleted_at) and fragment("COALESCE(?, 0) < 7", c.enrichment_status),
        select: %{
          id: c.id,
          name_en: c.name_en,
          name_ja: c.name_ja,
          about_en: c.about_en,
          gender: c.gender,
          age: c.age
        },
        order_by: [asc: c.id]
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
          Logger.info("[CharacterEnricher] Processing #{count}/#{total}: #{entry.name_en || entry.name_ja}")
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

    Logger.info("[CharacterEnricher] Done: #{success_count} ok, #{error_count} errors")

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
            Logger.warning("[CharacterEnricher] Parse failed for #{entry.id}: #{inspect(reason)}")
            mark_error(entry.id, "Parse: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.warning("[CharacterEnricher] API failed for #{entry.id}: #{inspect(reason)}")
        mark_error(entry.id, "API: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp system_prompt do
    """
    You are an anime/manga character database enrichment assistant. Given character information, generate enriched content in JSON format.

    Return ONLY valid JSON with these fields:
    {
      "name_en": "English name (given name first, family name last)",
      "name_ja": "Japanese name in Japanese characters",
      "about_en": "Improved/rewritten English character description (personality, role, background)",
      "about_ja": "Japanese translation of the description"
    }

    Guidelines:
    - name_en: Full name in English. Keep existing if provided and correct.
    - name_ja: Name in kanji/kana. Keep existing if provided.
    - about_en: Improve clarity, add detail about personality and role. 1-3 paragraphs.
    - about_ja: Natural Japanese translation, appropriate for character profiles

    Return ONLY the JSON object, no markdown, no explanation.
    """
  end

  defp build_prompt(entry) do
    """
    Character: #{entry.name_en || "Unknown"}
    Japanese Name: #{entry.name_ja || "N/A"}
    Gender: #{entry.gender || "Unknown"}
    Age: #{entry.age || "Unknown"}

    Current Description:
    #{entry.about_en || "(No description)"}

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
          name_en: data["name_en"],
          name_ja: data["name_ja"],
          about_en: data["about_en"],
          about_ja: data["about_ja"]
        }}

      {:ok, _} ->
        {:error, :invalid_structure}

      {:error, reason} ->
        {:error, {:json_parse, reason}}
    end
  end

  defp update_entry(id, data) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    from(c in "characters", prefix: "contents", where: c.id == ^id)
    |> Repo.update_all(
      set: [
        name_en: data.name_en,
        name_ja: data.name_ja,
        about_en: data.about_en,
        about_ja: data.about_ja,
        enrichment_status: 7,
        enrichment_error: nil,
        enriched_at: now
      ]
    )
  end

  defp mark_error(id, error) do
    from(c in "characters", prefix: "contents", where: c.id == ^id)
    |> Repo.update_all(set: [enrichment_error: error])
  end
end
