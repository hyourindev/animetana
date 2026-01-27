defmodule Yunaos.Jikan.Workers.PeopleWorksWorker do
  @moduledoc """
  Phase 5 worker: For each person, fetches TWO endpoints:
  - `GET /people/{mal_id}/anime` -> upserts `anime_staff`
  - `GET /people/{mal_id}/manga` -> upserts `manga_staff`
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  @rate_limit_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Fetches anime and manga works for every person."
  def run do
    Logger.info("[PeopleWorksWorker] Starting people works sync")

    people_list = Repo.all(from(p in "people", select: {p.id, p.mal_id}))
    total = length(people_list)
    Logger.info("[PeopleWorksWorker] Found #{total} people to process")

    people_list
    |> Enum.with_index(1)
    |> Enum.each(fn {{person_id, mal_id}, idx} ->
      try do
        Logger.info("[PeopleWorksWorker] Processing #{idx}/#{total} mal_id=#{mal_id}")
        process_person_anime(person_id, mal_id)
        Process.sleep(@rate_limit_ms)
        process_person_manga(person_id, mal_id)
      rescue
        e ->
          Logger.error(
            "[PeopleWorksWorker] Failed for person mal_id=#{mal_id}: #{inspect(e)}"
          )
      end

      Process.sleep(@rate_limit_ms)
    end)

    Logger.info("[PeopleWorksWorker] People works sync complete")
  end

  # ---------------------------------------------------------------------------
  # Processing
  # ---------------------------------------------------------------------------

  defp process_person_anime(person_id, mal_id) do
    case Client.get("/people/#{mal_id}/anime", []) do
      {:ok, %{"data" => data}} ->
        Enum.each(data, fn entry ->
          position = normalize_position(entry["position"])
          anime_mal_id = get_in(entry, ["anime", "mal_id"])

          case lookup_id("anime", anime_mal_id) do
            nil ->
              Logger.warning(
                "[PeopleWorksWorker] Anime not found: mal_id=#{anime_mal_id}"
              )

            anime_id ->
              Repo.insert_all(
                "anime_staff",
                [%{anime_id: anime_id, person_id: person_id, position: position}],
                on_conflict: :nothing
              )
          end
        end)

      {:error, :not_found} ->
        Logger.warning("[PeopleWorksWorker] Person anime not found on Jikan: mal_id=#{mal_id}")

      {:error, reason} ->
        Logger.error("[PeopleWorksWorker] API error for person anime mal_id=#{mal_id}: #{inspect(reason)}")
    end
  end

  defp process_person_manga(person_id, mal_id) do
    case Client.get("/people/#{mal_id}/manga", []) do
      {:ok, %{"data" => data}} ->
        Enum.each(data, fn entry ->
          position = normalize_position(entry["position"])
          manga_mal_id = get_in(entry, ["manga", "mal_id"])

          case lookup_id("manga", manga_mal_id) do
            nil ->
              Logger.warning(
                "[PeopleWorksWorker] Manga not found: mal_id=#{manga_mal_id}"
              )

            manga_id ->
              Repo.insert_all(
                "manga_staff",
                [%{manga_id: manga_id, person_id: person_id, position: position}],
                on_conflict: :nothing
              )
          end
        end)

      {:error, :not_found} ->
        Logger.warning("[PeopleWorksWorker] Person manga not found on Jikan: mal_id=#{mal_id}")

      {:error, reason} ->
        Logger.error("[PeopleWorksWorker] API error for person manga mal_id=#{mal_id}: #{inspect(reason)}")
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp normalize_position(nil), do: "unknown"

  defp normalize_position(position) when is_binary(position) do
    String.downcase(position)
  end

  defp lookup_id(table, mal_id) when is_integer(mal_id) do
    from(t in table, where: t.mal_id == ^mal_id, select: t.id)
    |> Repo.one()
  end

  defp lookup_id(_table, _mal_id), do: nil
end
