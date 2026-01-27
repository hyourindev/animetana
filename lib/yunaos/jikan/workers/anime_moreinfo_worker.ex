defmodule Yunaos.Jikan.Workers.AnimeMoreinfoWorker do
  @moduledoc """
  Phase 3 worker: For each anime in the database, fetches the moreinfo
  endpoint (`GET /anime/{mal_id}/moreinfo`) and updates the anime record's
  `more_info` field.
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  @rate_limit_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Iterates over all anime and fetches moreinfo for each."
  def run do
    Logger.info("[AnimeMoreinfoWorker] Starting anime moreinfo sync")

    anime_list = Repo.all(from(a in "anime", select: {a.id, a.mal_id}))
    total = length(anime_list)
    Logger.info("[AnimeMoreinfoWorker] Found #{total} anime to process")

    anime_list
    |> Enum.with_index(1)
    |> Enum.each(fn {{anime_id, mal_id}, index} ->
      try do
        Logger.info("[AnimeMoreinfoWorker] [#{index}/#{total}] Processing anime mal_id=#{mal_id}")
        process_anime(anime_id, mal_id)
      rescue
        e ->
          Logger.error(
            "[AnimeMoreinfoWorker] Failed for anime mal_id=#{mal_id}: #{inspect(e)}"
          )
      end

      Process.sleep(@rate_limit_ms)
    end)

    Logger.info("[AnimeMoreinfoWorker] Anime moreinfo sync complete")
    :ok
  end

  # ---------------------------------------------------------------------------
  # Processing
  # ---------------------------------------------------------------------------

  defp process_anime(anime_id, mal_id) do
    case Client.get("/anime/#{mal_id}/moreinfo") do
      {:ok, %{"data" => %{"moreinfo" => moreinfo}}} when is_binary(moreinfo) ->
        Repo.update_all(
          from(a in "anime", where: a.id == ^anime_id),
          set: [more_info: moreinfo]
        )

        Logger.debug("[AnimeMoreinfoWorker] Updated more_info for anime_id=#{anime_id}")

      {:ok, %{"data" => %{"moreinfo" => nil}}} ->
        Logger.debug("[AnimeMoreinfoWorker] No moreinfo for anime mal_id=#{mal_id}, skipping")

      {:error, :not_found} ->
        Logger.warning("[AnimeMoreinfoWorker] Not found on Jikan: mal_id=#{mal_id}")

      {:error, reason} ->
        Logger.error("[AnimeMoreinfoWorker] API error for mal_id=#{mal_id}: #{inspect(reason)}")

      _ ->
        Logger.debug("[AnimeMoreinfoWorker] No moreinfo data for anime mal_id=#{mal_id}")
    end
  end
end
