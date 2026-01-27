defmodule Yunaos.Jikan.Workers.MangaMoreinfoWorker do
  @moduledoc """
  Phase 4 worker: For each manga, fetches `GET /manga/{mal_id}/moreinfo`
  and updates the manga record with the additional information text.
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  @rate_limit_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Fetches moreinfo for every manga record."
  def run do
    Logger.info("[MangaMoreinfoWorker] Starting manga moreinfo sync")

    manga_list = Repo.all(from(m in "manga", select: {m.id, m.mal_id}))
    total = length(manga_list)
    Logger.info("[MangaMoreinfoWorker] Found #{total} manga to process")

    manga_list
    |> Enum.with_index(1)
    |> Enum.each(fn {{manga_id, mal_id}, idx} ->
      try do
        Logger.info("[MangaMoreinfoWorker] Processing #{idx}/#{total} mal_id=#{mal_id}")
        process_manga(manga_id, mal_id)
      rescue
        e ->
          Logger.error(
            "[MangaMoreinfoWorker] Failed for manga mal_id=#{mal_id}: #{inspect(e)}"
          )
      end

      Process.sleep(@rate_limit_ms)
    end)

    Logger.info("[MangaMoreinfoWorker] Manga moreinfo sync complete")
  end

  # ---------------------------------------------------------------------------
  # Processing
  # ---------------------------------------------------------------------------

  defp process_manga(manga_id, mal_id) do
    case Client.get("/manga/#{mal_id}/moreinfo", []) do
      {:ok, %{"data" => data}} ->
        moreinfo = data["moreinfo"]

        if moreinfo do
          now = DateTime.utc_now() |> DateTime.truncate(:second)

          from(m in "manga", where: m.id == ^manga_id)
          |> Repo.update_all(
            set: [
              more_info: moreinfo,
              updated_at: now
            ]
          )
        end

      {:error, :not_found} ->
        Logger.warning("[MangaMoreinfoWorker] Manga not found on Jikan: mal_id=#{mal_id}")

      {:error, reason} ->
        Logger.error("[MangaMoreinfoWorker] API error for mal_id=#{mal_id}: #{inspect(reason)}")
    end
  end
end
