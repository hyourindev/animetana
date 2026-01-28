defmodule Yunaos.Jikan.Workers.GenresWorker do
  @moduledoc """
  Fetches all anime and manga genres, themes, and demographics from the
  Jikan API and upserts them into their respective tables.

  The Jikan `/genres/{anime|manga}` endpoint accepts a `filter` parameter:
  - `genres` (default) → `genres` table
  - `themes` → `themes` table
  - `demographics` → `demographics` table

  For each category, fetches both the anime and manga variants, then merges:
  - If a `mal_id` appears in both, `type` is set to "both".
  - Otherwise, `type` is "anime" or "manga".
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  @rate_limit_ms 1_100

  # {api_filter, schema_table}
  @categories [
    {"genres", "contents.genres"},
    {"themes", "contents.themes"},
    {"demographics", "contents.demographics"}
  ]

  def run do
    Logger.info("[GenresWorker] Starting genre/theme/demographic collection")

    results =
      Enum.map(@categories, fn {filter, table} ->
        collect_category(filter, table)
      end)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil -> :ok
      error -> error
    end
  end

  defp collect_category(filter, table) do
    Logger.info("[GenresWorker] Collecting #{filter}")

    # Always pass the filter parameter - without it, Jikan returns ALL categories mixed
    params = [filter: filter]

    with {:ok, anime_body} <- Client.get("/genres/anime", params),
         _ <- Process.sleep(@rate_limit_ms),
         {:ok, manga_body} <- Client.get("/genres/manga", params) do
      anime_items = Map.get(anime_body, "data", [])
      manga_items = Map.get(manga_body, "data", [])

      Logger.info(
        "[GenresWorker] Fetched #{length(anime_items)} anime #{filter}, #{length(manga_items)} manga #{filter}"
      )

      merged = merge_items(anime_items, manga_items)
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      entries =
        Enum.map(merged, fn {mal_id, name, category} ->
          %{mal_id: mal_id, name_en: name, category: category, inserted_at: now}
        end)

      entries
      |> Enum.uniq_by(& &1.mal_id)
      |> Enum.chunk_every(50)
      |> Enum.each(fn batch ->
        Repo.insert_all(table, batch,
          on_conflict: {:replace, [:name_en, :category]},
          conflict_target: :mal_id
        )
      end)

      Logger.info("[GenresWorker] Upserted #{length(entries)} #{filter}")
      Process.sleep(@rate_limit_ms)
      {:ok, length(entries)}
    else
      {:error, reason} ->
        Logger.error("[GenresWorker] Failed to fetch #{filter}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp merge_items(anime_items, manga_items) do
    anime_map =
      anime_items
      |> Enum.map(fn item -> {item["mal_id"], item["name"]} end)
      |> Map.new()

    manga_map =
      manga_items
      |> Enum.map(fn item -> {item["mal_id"], item["name"]} end)
      |> Map.new()

    all_ids = MapSet.union(MapSet.new(Map.keys(anime_map)), MapSet.new(Map.keys(manga_map)))

    Enum.map(all_ids, fn mal_id ->
      in_anime = Map.has_key?(anime_map, mal_id)
      in_manga = Map.has_key?(manga_map, mal_id)

      # Category matches the contents.genre_category enum: 'anime', 'manga', 'both'
      category =
        cond do
          in_anime and in_manga -> "both"
          in_anime -> "anime"
          true -> "manga"
        end

      name = Map.get(anime_map, mal_id) || Map.get(manga_map, mal_id)
      {mal_id, name, category}
    end)
  end
end
