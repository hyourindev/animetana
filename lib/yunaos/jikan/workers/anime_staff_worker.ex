defmodule Yunaos.Jikan.Workers.AnimeStaffWorker do
  @moduledoc """
  Phase 3 worker: For each anime in the database, fetches the staff
  endpoint (`GET /anime/{mal_id}/staff`) and upserts anime_staff
  join-table entries.
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  @rate_limit_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Iterates over all anime and fetches staff for each."
  def run do
    Logger.info("[AnimeStaffWorker] Starting anime staff sync")

    anime_list = Repo.all(from(a in "anime", select: {a.id, a.mal_id}))
    total = length(anime_list)
    Logger.info("[AnimeStaffWorker] Found #{total} anime to process")

    anime_list
    |> Enum.with_index(1)
    |> Enum.each(fn {{anime_id, mal_id}, index} ->
      try do
        Logger.info("[AnimeStaffWorker] [#{index}/#{total}] Processing anime mal_id=#{mal_id}")
        process_anime(anime_id, mal_id)
      rescue
        e ->
          Logger.error(
            "[AnimeStaffWorker] Failed for anime mal_id=#{mal_id}: #{inspect(e)}"
          )
      end

      Process.sleep(@rate_limit_ms)
    end)

    Logger.info("[AnimeStaffWorker] Anime staff sync complete")
    :ok
  end

  # ---------------------------------------------------------------------------
  # Processing
  # ---------------------------------------------------------------------------

  defp process_anime(anime_id, mal_id) do
    case Client.get("/anime/#{mal_id}/staff") do
      {:ok, %{"data" => data}} when is_list(data) ->
        Enum.each(data, fn item ->
          process_staff_entry(anime_id, item)
        end)

      {:error, :not_found} ->
        Logger.warning("[AnimeStaffWorker] Not found on Jikan: mal_id=#{mal_id}")

      {:error, reason} ->
        Logger.error("[AnimeStaffWorker] API error for mal_id=#{mal_id}: #{inspect(reason)}")

      _ ->
        Logger.warning("[AnimeStaffWorker] Unexpected response for mal_id=#{mal_id}")
    end
  end

  defp process_staff_entry(anime_id, item) do
    person_data = item["person"] || %{}
    person_mal_id = person_data["mal_id"]
    positions = item["positions"] || []

    case lookup_id("people", person_mal_id) do
      nil ->
        Logger.debug(
          "[AnimeStaffWorker] Person not found in DB: mal_id=#{person_mal_id}, skipping"
        )

      person_id ->
        Enum.each(positions, fn position ->
          Repo.insert_all(
            "anime_staff",
            [%{anime_id: anime_id, person_id: person_id, position: String.downcase(position)}],
            on_conflict: :nothing
          )
        end)
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp lookup_id(table, mal_id) when is_integer(mal_id) do
    from(t in table, where: t.mal_id == ^mal_id, select: t.id)
    |> Repo.one()
  end

  defp lookup_id(_table, _mal_id), do: nil
end
