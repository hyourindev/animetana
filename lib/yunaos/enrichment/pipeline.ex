defmodule Yunaos.Enrichment.Pipeline do
  @moduledoc """
  Orchestrates the AI enrichment pipeline.

  Queries unenriched anime/manga rows, batches them, sends to Gemini
  via Vercel AI Gateway, parses responses, and writes results to the DB.

  Resume-safe: uses the `enriched` boolean column to skip already-processed rows.
  """

  require Logger

  import Ecto.Query

  alias Yunaos.Repo
  alias Yunaos.Enrichment.{GeminiClient, Prompt, Parser}

  @doc """
  Runs the enrichment pipeline for the given type (:anime or :manga).

  Options:
    - :limit — max number of rows to process (default: all)
    - :batch_size — rows per API request (default: from config)
    - :delay_ms — delay between requests (default: from config)
  """
  @spec run(:anime | :manga, keyword()) :: :ok
  def run(type, opts \\ []) when type in [:anime, :manga] do
    table = Atom.to_string(type)
    join_table = "#{table}_sub_genres"

    config = Application.get_env(:yunaos, :enrichment)
    batch_size = opts[:batch_size] || config[:batch_size] || 25
    delay_ms = opts[:delay_ms] || config[:request_delay_ms] || 500
    limit = opts[:limit]

    Logger.info("[Enrichment] Starting #{type} enrichment (batch_size=#{batch_size})")

    # Load genres from DB for the system prompt
    genres = load_genres()
    Logger.info("[Enrichment] Loaded #{length(genres)} genres")

    # Load sub-genres with full details for the system prompt
    sub_genres = load_sub_genres()
    Logger.info("[Enrichment] Loaded #{length(sub_genres)} sub-genres")

    # Build sub-genre name→id lookup for the parser
    sub_genre_lookup = Map.new(sub_genres, fn sg -> {sg.name, sg.id} end)

    # Build system prompt once (includes all genres + sub-genres with descriptions)
    system_prompt = Prompt.system_prompt(genres, sub_genres)

    Logger.info(
      "[Enrichment] System prompt built (#{String.length(system_prompt)} chars, " <>
        "~#{div(String.length(system_prompt), 4)} tokens est.)"
    )

    # Query unenriched rows with synopsis
    rows = fetch_unenriched(table, limit)
    total = length(rows)

    Logger.info("[Enrichment] Found #{total} unenriched #{type} rows with synopsis")

    if total == 0 do
      Logger.info("[Enrichment] Nothing to enrich. Done.")
      :ok
    else
      rows
      |> Enum.chunk_every(batch_size)
      |> Enum.with_index(1)
      |> Enum.each(fn {batch, batch_num} ->
        total_batches = ceil(total / batch_size)

        Logger.info(
          "[Enrichment] Processing batch #{batch_num}/#{total_batches} " <>
            "(#{length(batch)} rows)"
        )

        process_batch(batch, system_prompt, sub_genre_lookup, table, join_table)

        if batch_num < total_batches do
          Process.sleep(delay_ms)
        end
      end)

      Logger.info("[Enrichment] Completed #{type} enrichment (#{total} rows)")
      :ok
    end
  end

  defp fetch_unenriched(table, limit) do
    # Build base query for unenriched rows with a synopsis
    genre_join_table =
      case table do
        "anime" -> "anime_genres"
        "manga" -> "manga_genres"
      end

    fk_col =
      case table do
        "anime" -> :anime_id
        "manga" -> :manga_id
      end

    base =
      from(r in table,
        where: r.enriched != true and not is_nil(r.synopsis) and r.synopsis != "",
        left_lateral_join:
          g in subquery(
            from(ag in genre_join_table,
              join: genre in "genres",
              on: genre.id == ag.genre_id,
              where: field(ag, ^fk_col) == parent_as(:row).id,
              select: %{names: fragment("array_agg(?)", genre.name)}
            )
          ),
        on: true,
        as: :row,
        select: %{
          id: r.id,
          title: r.title,
          title_japanese: r.title_japanese,
          synopsis: r.synopsis,
          genres: g.names
        },
        order_by: [asc: r.id]
      )

    query = if limit, do: from(r in base, limit: ^limit), else: base

    Repo.all(query)
  rescue
    # Fallback if lateral join fails (e.g., missing join table)
    e ->
      Logger.warning("[Enrichment] Genre join query failed: #{inspect(e)}. Falling back to simple query.")
      fetch_unenriched_simple(table, limit)
  end

  defp fetch_unenriched_simple(table, limit) do
    base =
      from(r in table,
        where: r.enriched != true and not is_nil(r.synopsis) and r.synopsis != "",
        select: %{
          id: r.id,
          title: r.title,
          title_japanese: r.title_japanese,
          synopsis: r.synopsis,
          genres: fragment("'{}'::text[]")
        },
        order_by: [asc: r.id]
      )

    query = if limit, do: from(r in base, limit: ^limit), else: base
    Repo.all(query)
  end

  defp load_genres do
    from(g in "genres",
      select: %{
        id: g.id,
        name: g.name,
        name_ja: g.name_ja
      },
      order_by: [asc: g.id]
    )
    |> Repo.all()
  end

  defp load_sub_genres do
    from(sg in "sub_genres",
      select: %{
        id: sg.id,
        name: sg.name,
        name_ja: sg.name_ja,
        description: sg.description
      },
      order_by: [asc: sg.id]
    )
    |> Repo.all()
  end

  defp process_batch(rows, system_prompt, sub_genre_lookup, table, join_table) do
    # Normalize genres from arrays/nil to lists of strings
    normalized_rows =
      Enum.map(rows, fn row ->
        genres =
          case row.genres do
            nil -> []
            list when is_list(list) -> Enum.reject(list, &is_nil/1)
            _ -> []
          end

        %{row | genres: genres}
      end)

    user_prompt = Prompt.user_prompt(normalized_rows)

    case GeminiClient.chat(system_prompt, user_prompt) do
      {:ok, raw_json} ->
        case Parser.parse(raw_json, sub_genre_lookup) do
          {:ok, enrichments} ->
            apply_enrichments(enrichments, table, join_table)

          {:error, reason} ->
            ids = Enum.map(rows, & &1.id)
            Logger.error("[Enrichment] Parse error for IDs #{inspect(ids)}: #{inspect(reason)}")
        end

      {:error, reason} ->
        ids = Enum.map(rows, & &1.id)
        Logger.error("[Enrichment] API error for IDs #{inspect(ids)}: #{inspect(reason)}")
    end
  end

  defp apply_enrichments(enrichments, table, join_table) do
    Enum.each(enrichments, fn enrichment ->
      if is_nil(enrichment) or is_nil(enrichment.id) do
        Logger.warning("[Enrichment] Skipping nil enrichment")
      else
        apply_single_enrichment(enrichment, table, join_table)
      end
    end)
  end

  defp apply_single_enrichment(enrichment, table, join_table) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    # Update the main record
    update_fields =
      %{
        synopsis_ja: enrichment.synopsis_ja,
        mood_tags: maybe_encode(enrichment.mood_tags),
        content_warnings: maybe_encode(enrichment.content_warnings),
        pacing: enrichment.pacing,
        art_style: enrichment.art_style,
        art_style_ja: enrichment.art_style_ja,
        target_audience: enrichment.target_audience,
        fun_facts: maybe_encode(enrichment.fun_facts),
        similar_to: maybe_encode(enrichment.similar_to),
        enriched: true,
        updated_at: now
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    from(r in table, where: r.id == ^enrichment.id)
    |> Repo.update_all(set: Enum.to_list(update_fields))

    # Insert sub-genre associations
    fk_col =
      case table do
        "anime" -> :anime_id
        "manga" -> :manga_id
      end

    if enrichment.sub_genre_ids != [] do
      sub_genre_entries =
        Enum.map(enrichment.sub_genre_ids, fn sg_id ->
          %{fk_col => enrichment.id, sub_genre_id: sg_id}
        end)

      Repo.insert_all(join_table, sub_genre_entries, on_conflict: :nothing)
    end

    Logger.debug("[Enrichment] Enriched #{table} ##{enrichment.id}")
  end

  # JSONB columns accept Elixir maps/lists directly via Postgrex
  defp maybe_encode(nil), do: nil
  defp maybe_encode(val), do: val
end
