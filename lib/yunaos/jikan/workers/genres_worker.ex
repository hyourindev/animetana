defmodule Yunaos.Jikan.Workers.GenresWorker do
  @moduledoc """
  Fetches all anime and manga genres from the Jikan API and upserts them
  into the `genres` table.

  Calls `GET /genres/anime` and `GET /genres/manga`, then merges results:
  - If a `mal_id` appears in both anime and manga responses, `type` is set to "both".
  - Otherwise, `type` is "anime" or "manga".
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  @rate_limit_ms 1_100

  def run do
    Logger.info("[GenresWorker] Starting genre collection")

    with {:ok, anime_body} <- Client.get("/genres/anime", %{}),
         _ <- Process.sleep(@rate_limit_ms),
         {:ok, manga_body} <- Client.get("/genres/manga", %{}) do
      anime_genres = Map.get(anime_body, "data", [])
      manga_genres = Map.get(manga_body, "data", [])

      Logger.info(
        "[GenresWorker] Fetched #{length(anime_genres)} anime genres, #{length(manga_genres)} manga genres"
      )

      merged = merge_genres(anime_genres, manga_genres)

      Logger.info("[GenresWorker] Merged into #{length(merged)} unique genres")

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      entries =
        Enum.map(merged, fn {mal_id, name, type} ->
          %{
            mal_id: mal_id,
            name: name,
            type: type,
            inserted_at: now
          }
        end)

      # Upsert in batches using insert_all with on_conflict
      entries
      |> Enum.chunk_every(50)
      |> Enum.each(fn batch ->
        Repo.insert_all("genres", batch,
          on_conflict: {:replace, [:name, :type]},
          conflict_target: :mal_id
        )
      end)

      Logger.info("[GenresWorker] Successfully upserted #{length(entries)} genres")
      {:ok, length(entries)}
    else
      {:error, reason} ->
        Logger.error("[GenresWorker] Failed to fetch genres: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Merges anime and manga genre lists. Returns a list of {mal_id, name, type} tuples.
  defp merge_genres(anime_genres, manga_genres) do
    anime_map =
      anime_genres
      |> Enum.map(fn item -> {item["mal_id"], item["name"]} end)
      |> Map.new()

    manga_map =
      manga_genres
      |> Enum.map(fn item -> {item["mal_id"], item["name"]} end)
      |> Map.new()

    all_ids = MapSet.union(MapSet.new(Map.keys(anime_map)), MapSet.new(Map.keys(manga_map)))

    Enum.map(all_ids, fn mal_id ->
      in_anime = Map.has_key?(anime_map, mal_id)
      in_manga = Map.has_key?(manga_map, mal_id)

      type =
        cond do
          in_anime and in_manga -> "both"
          in_anime -> "anime"
          true -> "manga"
        end

      name = Map.get(anime_map, mal_id) || Map.get(manga_map, mal_id)
      {mal_id, name, type}
    end)
  end
end
