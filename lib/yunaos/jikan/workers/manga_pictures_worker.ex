defmodule Yunaos.Jikan.Workers.MangaPicturesWorker do
  @moduledoc """
  Phase 4 worker: For each manga, fetches `GET /manga/{mal_id}/pictures`
  and upserts image entries into the `pictures` table with
  `imageable_type` = "manga".
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  @rate_limit_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Fetches pictures for every manga record."
  def run do
    Logger.info("[MangaPicturesWorker] Starting manga pictures sync")

    manga_list = Repo.all(from(m in "manga", select: {m.id, m.mal_id}))
    total = length(manga_list)
    Logger.info("[MangaPicturesWorker] Found #{total} manga to process")

    manga_list
    |> Enum.with_index(1)
    |> Enum.each(fn {{manga_id, mal_id}, idx} ->
      try do
        Logger.info("[MangaPicturesWorker] Processing #{idx}/#{total} mal_id=#{mal_id}")
        process_manga(manga_id, mal_id)
      rescue
        e ->
          Logger.error(
            "[MangaPicturesWorker] Failed for manga mal_id=#{mal_id}: #{inspect(e)}"
          )
      end

      Process.sleep(@rate_limit_ms)
    end)

    Logger.info("[MangaPicturesWorker] Manga pictures sync complete")
  end

  # ---------------------------------------------------------------------------
  # Processing
  # ---------------------------------------------------------------------------

  defp process_manga(manga_id, mal_id) do
    case Client.get("/manga/#{mal_id}/pictures", []) do
      {:ok, %{"data" => data}} ->
        upsert_pictures(manga_id, data)

      {:error, :not_found} ->
        Logger.warning("[MangaPicturesWorker] Manga not found on Jikan: mal_id=#{mal_id}")

      {:error, reason} ->
        Logger.error("[MangaPicturesWorker] API error for mal_id=#{mal_id}: #{inspect(reason)}")
    end
  end

  defp upsert_pictures(manga_id, pictures) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Enum.each(pictures, fn pic ->
      jpg = pic["jpg"] || %{}
      image_url = jpg["large_image_url"] || jpg["image_url"]
      small_image_url = jpg["small_image_url"] || jpg["image_url"]

      if image_url do
        attrs = %{
          imageable_type: "manga",
          imageable_id: manga_id,
          image_url: image_url,
          small_image_url: small_image_url,
          inserted_at: now,
          updated_at: now
        }

        Repo.insert_all(
          "pictures",
          [attrs],
          on_conflict: :nothing,
          conflict_target: [:imageable_type, :imageable_id, :image_url]
        )
      end
    end)
  end
end
