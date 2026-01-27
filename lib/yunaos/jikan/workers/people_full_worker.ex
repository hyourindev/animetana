defmodule Yunaos.Jikan.Workers.PeopleFullWorker do
  @moduledoc """
  Phase 5 worker: For each person, fetches `GET /people/{mal_id}/full`
  and updates the person record with enriched fields. Also upserts
  `anime_staff` entries from the response's anime array.

  The `voices` array from this endpoint provides voice actor data WITHOUT
  a language field, so it is skipped. The `anime_characters_worker` handles
  voice actor mappings with proper language data.
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  @rate_limit_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Fetches full details for every person record."
  def run do
    Logger.info("[PeopleFullWorker] Starting people full enrichment")

    people_list = Repo.all(from(p in "people", select: {p.id, p.mal_id}))
    total = length(people_list)
    Logger.info("[PeopleFullWorker] Found #{total} people to enrich")

    people_list
    |> Enum.with_index(1)
    |> Enum.each(fn {{id, mal_id}, idx} ->
      try do
        Logger.info("[PeopleFullWorker] Processing #{idx}/#{total} mal_id=#{mal_id}")
        process_person(id, mal_id)
      rescue
        e ->
          Logger.error(
            "[PeopleFullWorker] Failed for person mal_id=#{mal_id}: #{inspect(e)}"
          )
      end

      Process.sleep(@rate_limit_ms)
    end)

    Logger.info("[PeopleFullWorker] People full enrichment complete")
  end

  # ---------------------------------------------------------------------------
  # Processing
  # ---------------------------------------------------------------------------

  defp process_person(person_id, mal_id) do
    case Client.get("/people/#{mal_id}/full", []) do
      {:ok, %{"data" => data}} ->
        update_person(person_id, data)
        upsert_anime_staff(person_id, data["anime"] || [])
        # voices array is intentionally skipped - anime_characters_worker
        # handles voice actor mappings with proper language data

      {:error, :not_found} ->
        Logger.warning("[PeopleFullWorker] Person not found on Jikan: mal_id=#{mal_id}")

      {:error, reason} ->
        Logger.error("[PeopleFullWorker] API error for mal_id=#{mal_id}: #{inspect(reason)}")
    end
  end

  defp update_person(person_id, data) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    from(p in "people", where: p.id == ^person_id)
    |> Repo.update_all(
      set: [
        about: data["about"],
        given_name: data["given_name"],
        family_name: data["family_name"],
        alternate_names: data["alternate_names"] || [],
        birthday: parse_date(data["birthday"]),
        website_url: data["website_url"],
        image_url: get_in(data, ["images", "jpg", "image_url"]),
        favorites_count: data["favorites"] || 0,
        updated_at: now
      ]
    )
  end

  defp upsert_anime_staff(person_id, anime_entries) do
    Enum.each(anime_entries, fn entry ->
      position = normalize_position(entry["position"])
      anime_mal_id = get_in(entry, ["anime", "mal_id"])

      case lookup_id("anime", anime_mal_id) do
        nil ->
          Logger.warning(
            "[PeopleFullWorker] Anime not found: mal_id=#{anime_mal_id}"
          )

        anime_id ->
          Repo.insert_all(
            "anime_staff",
            [%{anime_id: anime_id, person_id: person_id, position: position}],
            on_conflict: :nothing
          )
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp normalize_position(nil), do: "unknown"

  defp normalize_position(position) when is_binary(position) do
    String.downcase(position)
  end

  defp parse_date(nil), do: nil

  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(String.slice(date_string, 0, 10)) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end

  defp parse_date(_), do: nil

  defp lookup_id(table, mal_id) when is_integer(mal_id) do
    from(t in table, where: t.mal_id == ^mal_id, select: t.id)
    |> Repo.one()
  end

  defp lookup_id(_table, _mal_id), do: nil
end
