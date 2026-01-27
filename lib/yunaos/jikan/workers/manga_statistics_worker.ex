defmodule Yunaos.Jikan.Workers.MangaStatisticsWorker do
  @moduledoc """
  Phase 4 worker: For each manga, fetches `GET /manga/{mal_id}/statistics`
  and upserts score distribution data into the `score_distributions` table
  with `scoreable_type` = "manga".
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  @rate_limit_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Fetches statistics for every manga record."
  def run do
    Logger.info("[MangaStatisticsWorker] Starting manga statistics sync")

    manga_list = Repo.all(from(m in "manga", select: {m.id, m.mal_id}))
    total = length(manga_list)
    Logger.info("[MangaStatisticsWorker] Found #{total} manga to process")

    manga_list
    |> Enum.with_index(1)
    |> Enum.each(fn {{manga_id, mal_id}, idx} ->
      try do
        Logger.info("[MangaStatisticsWorker] Processing #{idx}/#{total} mal_id=#{mal_id}")
        process_manga(manga_id, mal_id)
      rescue
        e ->
          Logger.error(
            "[MangaStatisticsWorker] Failed for manga mal_id=#{mal_id}: #{inspect(e)}"
          )
      end

      Process.sleep(@rate_limit_ms)
    end)

    Logger.info("[MangaStatisticsWorker] Manga statistics sync complete")
  end

  # ---------------------------------------------------------------------------
  # Processing
  # ---------------------------------------------------------------------------

  defp process_manga(manga_id, mal_id) do
    case Client.get("/manga/#{mal_id}/statistics", []) do
      {:ok, %{"data" => data}} ->
        upsert_score_distributions(manga_id, data["scores"] || [])

      {:error, :not_found} ->
        Logger.warning("[MangaStatisticsWorker] Manga not found on Jikan: mal_id=#{mal_id}")

      {:error, reason} ->
        Logger.error("[MangaStatisticsWorker] API error for mal_id=#{mal_id}: #{inspect(reason)}")
    end
  end

  defp upsert_score_distributions(manga_id, scores) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Enum.each(scores, fn score_entry ->
      attrs = %{
        scoreable_type: "manga",
        scoreable_id: manga_id,
        score: score_entry["score"],
        votes: score_entry["votes"],
        percentage: score_entry["percentage"],
        inserted_at: now,
        updated_at: now
      }

      Repo.insert_all(
        "score_distributions",
        [attrs],
        on_conflict: {:replace, [:votes, :percentage, :updated_at]},
        conflict_target: [:scoreable_type, :scoreable_id, :score]
      )
    end)
  end
end
