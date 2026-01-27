defmodule Yunaos.Jikan.Workers.AnimePicturesWorker do
  @moduledoc """
  Phase 3 worker: For each anime in the database, fetches the pictures
  endpoint (`GET /anime/{mal_id}/pictures`) and replaces existing picture
  records in the `pictures` table.
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  @rate_limit_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Iterates over all anime and fetches pictures for each."
  def run do
    Logger.info("[AnimePicturesWorker] Starting anime pictures sync")

    anime_list = Repo.all(from(a in "anime", select: {a.id, a.mal_id}))
    total = length(anime_list)
    Logger.info("[AnimePicturesWorker] Found #{total} anime to process")

    anime_list
    |> Enum.with_index(1)
    |> Enum.each(fn {{anime_id, mal_id}, index} ->
      try do
        Logger.info("[AnimePicturesWorker] [#{index}/#{total}] Processing anime mal_id=#{mal_id}")
        process_anime(anime_id, mal_id)
      rescue
        e ->
          Logger.error(
            "[AnimePicturesWorker] Failed for anime mal_id=#{mal_id}: #{inspect(e)}"
          )
      end

      Process.sleep(@rate_limit_ms)
    end)

    Logger.info("[AnimePicturesWorker] Anime pictures sync complete")
    :ok
  end

  # ---------------------------------------------------------------------------
  # Processing
  # ---------------------------------------------------------------------------

  defp process_anime(anime_id, mal_id) do
    case Client.get("/anime/#{mal_id}/pictures") do
      {:ok, %{"data" => data}} when is_list(data) ->
        replace_pictures(anime_id, data)

      {:error, :not_found} ->
        Logger.warning("[AnimePicturesWorker] Not found on Jikan: mal_id=#{mal_id}")

      {:error, reason} ->
        Logger.error("[AnimePicturesWorker] API error for mal_id=#{mal_id}: #{inspect(reason)}")

      _ ->
        Logger.warning("[AnimePicturesWorker] Unexpected response for mal_id=#{mal_id}")
    end
  end

  defp replace_pictures(anime_id, data) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries =
      Enum.map(data, fn picture ->
        jpg = picture["jpg"] || %{}
        webp = picture["webp"] || %{}

        %{
          imageable_type: "anime",
          imageable_id: anime_id,
          image_url: jpg["image_url"],
          small_image_url: jpg["small_image_url"],
          large_image_url: jpg["large_image_url"],
          webp_image_url: webp["image_url"],
          webp_small_image_url: webp["small_image_url"],
          webp_large_image_url: webp["large_image_url"],
          inserted_at: now,
          updated_at: now
        }
      end)

    # Delete existing pictures for this anime, then insert fresh
    Repo.delete_all(
      from(p in "pictures",
        where: p.imageable_type == "anime" and p.imageable_id == ^anime_id
      )
    )

    if entries != [] do
      entries
      |> Enum.chunk_every(50)
      |> Enum.each(fn batch ->
        Repo.insert_all("pictures", batch)
      end)
    end

    Logger.debug("[AnimePicturesWorker] Replaced #{length(entries)} pictures for anime_id=#{anime_id}")
  end
end
