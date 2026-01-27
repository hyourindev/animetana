defmodule Yunaos.Jikan.Workers.AnimeStatisticsWorker do
  @moduledoc """
  Phase 3 worker: For each anime in the database, fetches the statistics
  endpoint (`GET /anime/{mal_id}/statistics`) and upserts score distribution
  entries into the `score_distributions` table.
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  @rate_limit_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Iterates over all anime and fetches statistics for each."
  def run do
    Logger.info("[AnimeStatisticsWorker] Starting anime statistics sync")

    anime_list = Repo.all(from(a in "anime", select: {a.id, a.mal_id}))
    total = length(anime_list)
    Logger.info("[AnimeStatisticsWorker] Found #{total} anime to process")

    anime_list
    |> Enum.with_index(1)
    |> Enum.each(fn {{anime_id, mal_id}, index} ->
      try do
        Logger.info("[AnimeStatisticsWorker] [#{index}/#{total}] Processing anime mal_id=#{mal_id}")
        process_anime(anime_id, mal_id)
      rescue
        e ->
          Logger.error(
            "[AnimeStatisticsWorker] Failed for anime mal_id=#{mal_id}: #{inspect(e)}"
          )
      end

      Process.sleep(@rate_limit_ms)
    end)

    Logger.info("[AnimeStatisticsWorker] Anime statistics sync complete")
    :ok
  end

  # ---------------------------------------------------------------------------
  # Processing
  # ---------------------------------------------------------------------------

  defp process_anime(anime_id, mal_id) do
    case Client.get("/anime/#{mal_id}/statistics") do
      {:ok, %{"data" => data}} ->
        scores = data["scores"] || []
        upsert_score_distributions(anime_id, scores)

      {:error, :not_found} ->
        Logger.warning("[AnimeStatisticsWorker] Not found on Jikan: mal_id=#{mal_id}")

      {:error, reason} ->
        Logger.error("[AnimeStatisticsWorker] API error for mal_id=#{mal_id}: #{inspect(reason)}")
    end
  end

  defp upsert_score_distributions(anime_id, scores) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries =
      Enum.map(scores, fn score_entry ->
        %{
          scoreable_type: "anime",
          scoreable_id: anime_id,
          score: score_entry["score"],
          votes: score_entry["votes"],
          percentage: score_entry["percentage"],
          inserted_at: now,
          updated_at: now
        }
      end)

    entries
    |> Enum.chunk_every(50)
    |> Enum.each(fn batch ->
      Repo.insert_all("score_distributions", batch,
        on_conflict: {:replace, [:votes, :percentage, :updated_at]},
        conflict_target: [:scoreable_type, :scoreable_id, :score]
      )
    end)

    Logger.debug("[AnimeStatisticsWorker] Upserted #{length(entries)} score distributions for anime_id=#{anime_id}")
  end
end
