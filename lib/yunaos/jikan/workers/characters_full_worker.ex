defmodule Yunaos.Jikan.Workers.CharactersFullWorker do
  @moduledoc """
  Phase 5 worker: For each character, fetches `GET /characters/{mal_id}/full`
  and updates the character record with enriched fields. Also upserts
  `anime_characters` and `manga_characters` from the response's anime/manga arrays.

  The `voices` array from this endpoint provides character-level voice actors
  WITHOUT a specific anime context, so it is skipped. The `anime_characters_worker`
  handles per-anime voice actors more accurately.
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  @rate_limit_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Fetches full details for every character record."
  def run do
    Logger.info("[CharactersFullWorker] Starting character full enrichment")

    character_list = Repo.all(from(c in "characters", select: {c.id, c.mal_id}))
    total = length(character_list)
    Logger.info("[CharactersFullWorker] Found #{total} characters to enrich")

    character_list
    |> Enum.with_index(1)
    |> Enum.each(fn {{id, mal_id}, idx} ->
      try do
        Logger.info("[CharactersFullWorker] Processing #{idx}/#{total} mal_id=#{mal_id}")
        process_character(id, mal_id)
      rescue
        e ->
          Logger.error(
            "[CharactersFullWorker] Failed for character mal_id=#{mal_id}: #{inspect(e)}"
          )
      end

      Process.sleep(@rate_limit_ms)
    end)

    Logger.info("[CharactersFullWorker] Character full enrichment complete")
  end

  # ---------------------------------------------------------------------------
  # Processing
  # ---------------------------------------------------------------------------

  defp process_character(character_id, mal_id) do
    case Client.get("/characters/#{mal_id}/full", []) do
      {:ok, %{"data" => data}} ->
        update_character(character_id, data)
        upsert_anime_characters(character_id, data["anime"] || [])
        upsert_manga_characters(character_id, data["manga"] || [])
        # voices array is intentionally skipped - anime_characters_worker
        # handles per-anime voice actors with proper context

      {:error, :not_found} ->
        Logger.warning("[CharactersFullWorker] Character not found on Jikan: mal_id=#{mal_id}")

      {:error, reason} ->
        Logger.error("[CharactersFullWorker] API error for mal_id=#{mal_id}: #{inspect(reason)}")
    end
  end

  defp update_character(character_id, data) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    from(c in "characters", where: c.id == ^character_id)
    |> Repo.update_all(
      set: [
        about: data["about"],
        name_kanji: data["name_kanji"],
        nicknames: data["nicknames"] || [],
        favorites_count: data["favorites"] || 0,
        image_url: get_in(data, ["images", "jpg", "image_url"]),
        updated_at: now
      ]
    )
  end

  defp upsert_anime_characters(character_id, anime_entries) do
    Enum.each(anime_entries, fn entry ->
      role = normalize_role(entry["role"])
      anime_mal_id = get_in(entry, ["anime", "mal_id"])

      case lookup_id("anime", anime_mal_id) do
        nil ->
          Logger.warning(
            "[CharactersFullWorker] Anime not found: mal_id=#{anime_mal_id}"
          )

        anime_id ->
          Repo.insert_all(
            "anime_characters",
            [%{anime_id: anime_id, character_id: character_id, role: role}],
            on_conflict: :nothing
          )
      end
    end)
  end

  defp upsert_manga_characters(character_id, manga_entries) do
    Enum.each(manga_entries, fn entry ->
      role = normalize_role(entry["role"])
      manga_mal_id = get_in(entry, ["manga", "mal_id"])

      case lookup_id("manga", manga_mal_id) do
        nil ->
          Logger.warning(
            "[CharactersFullWorker] Manga not found: mal_id=#{manga_mal_id}"
          )

        manga_id ->
          Repo.insert_all(
            "manga_characters",
            [%{manga_id: manga_id, character_id: character_id, role: role}],
            on_conflict: :nothing
          )
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp normalize_role(nil), do: "supporting"

  defp normalize_role(role) when is_binary(role) do
    String.downcase(role)
  end

  defp lookup_id(table, mal_id) when is_integer(mal_id) do
    from(t in table, where: t.mal_id == ^mal_id, select: t.id)
    |> Repo.one()
  end

  defp lookup_id(_table, _mal_id), do: nil
end
