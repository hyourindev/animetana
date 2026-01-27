defmodule Yunaos.Jikan.Workers.AnimeCharactersWorker do
  @moduledoc """
  Phase 3 worker: For each anime in the database, fetches the characters
  endpoint (`GET /anime/{mal_id}/characters`) and upserts anime_characters
  and character_voice_actors join-table entries.
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  @rate_limit_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Iterates over all anime and fetches characters for each."
  def run do
    Logger.info("[AnimeCharactersWorker] Starting anime characters sync")

    anime_list = Repo.all(from(a in "anime", select: {a.id, a.mal_id}))
    total = length(anime_list)
    Logger.info("[AnimeCharactersWorker] Found #{total} anime to process")

    anime_list
    |> Enum.with_index(1)
    |> Enum.each(fn {{anime_id, mal_id}, index} ->
      try do
        Logger.info("[AnimeCharactersWorker] [#{index}/#{total}] Processing anime mal_id=#{mal_id}")
        process_anime(anime_id, mal_id)
      rescue
        e ->
          Logger.error(
            "[AnimeCharactersWorker] Failed for anime mal_id=#{mal_id}: #{inspect(e)}"
          )
      end

      Process.sleep(@rate_limit_ms)
    end)

    Logger.info("[AnimeCharactersWorker] Anime characters sync complete")
    :ok
  end

  # ---------------------------------------------------------------------------
  # Processing
  # ---------------------------------------------------------------------------

  defp process_anime(anime_id, mal_id) do
    case Client.get("/anime/#{mal_id}/characters") do
      {:ok, %{"data" => data}} when is_list(data) ->
        Enum.each(data, fn item ->
          process_character_entry(anime_id, item)
        end)

      {:error, :not_found} ->
        Logger.warning("[AnimeCharactersWorker] Not found on Jikan: mal_id=#{mal_id}")

      {:error, reason} ->
        Logger.error("[AnimeCharactersWorker] API error for mal_id=#{mal_id}: #{inspect(reason)}")

      _ ->
        Logger.warning("[AnimeCharactersWorker] Unexpected response for mal_id=#{mal_id}")
    end
  end

  defp process_character_entry(anime_id, item) do
    character_data = item["character"] || %{}
    character_mal_id = character_data["mal_id"]
    role = normalize_role(item["role"])

    case lookup_id("characters", character_mal_id) do
      nil ->
        Logger.debug(
          "[AnimeCharactersWorker] Character not found in DB: mal_id=#{character_mal_id}, skipping"
        )

      character_id ->
        Repo.insert_all(
          "anime_characters",
          [%{anime_id: anime_id, character_id: character_id, role: role}],
          on_conflict: :nothing
        )

        process_voice_actors(character_id, anime_id, item["voice_actors"] || [])
    end
  end

  defp process_voice_actors(character_id, anime_id, voice_actors) do
    Enum.each(voice_actors, fn va ->
      person_data = va["person"] || %{}
      person_mal_id = person_data["mal_id"]
      language = normalize_string(va["language"])

      case lookup_id("people", person_mal_id) do
        nil ->
          Logger.debug(
            "[AnimeCharactersWorker] Person not found in DB: mal_id=#{person_mal_id}, skipping"
          )

        person_id ->
          Repo.insert_all(
            "character_voice_actors",
            [%{character_id: character_id, person_id: person_id, anime_id: anime_id, language: language}],
            on_conflict: :nothing
          )
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp lookup_id(table, mal_id) when is_integer(mal_id) do
    from(t in table, where: t.mal_id == ^mal_id, select: t.id)
    |> Repo.one()
  end

  defp lookup_id(_table, _mal_id), do: nil

  defp normalize_role(nil), do: "unknown"
  defp normalize_role(role) when is_binary(role), do: String.downcase(role)

  defp normalize_string(nil), do: nil
  defp normalize_string(s) when is_binary(s), do: String.downcase(s)
end
