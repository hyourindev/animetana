defmodule Yunaos.Jikan.Workers.MangaCharactersWorker do
  @moduledoc """
  Phase 4 worker: For each manga, fetches `GET /manga/{mal_id}/characters`
  and upserts character-manga associations into the `manga_characters` table.
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  @rate_limit_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Fetches characters for every manga record."
  def run do
    Logger.info("[MangaCharactersWorker] Starting manga characters sync")

    manga_list = Repo.all(from(m in "manga", select: {m.id, m.mal_id}))
    total = length(manga_list)
    Logger.info("[MangaCharactersWorker] Found #{total} manga to process")

    manga_list
    |> Enum.with_index(1)
    |> Enum.each(fn {{manga_id, mal_id}, idx} ->
      try do
        Logger.info("[MangaCharactersWorker] Processing #{idx}/#{total} mal_id=#{mal_id}")
        process_manga(manga_id, mal_id)
      rescue
        e ->
          Logger.error(
            "[MangaCharactersWorker] Failed for manga mal_id=#{mal_id}: #{inspect(e)}"
          )
      end

      Process.sleep(@rate_limit_ms)
    end)

    Logger.info("[MangaCharactersWorker] Manga characters sync complete")
  end

  # ---------------------------------------------------------------------------
  # Processing
  # ---------------------------------------------------------------------------

  defp process_manga(manga_id, mal_id) do
    case Client.get("/manga/#{mal_id}/characters", []) do
      {:ok, %{"data" => data}} ->
        Enum.each(data, fn entry ->
          upsert_manga_character(manga_id, entry)
        end)

      {:error, :not_found} ->
        Logger.warning("[MangaCharactersWorker] Manga not found on Jikan: mal_id=#{mal_id}")

      {:error, reason} ->
        Logger.error("[MangaCharactersWorker] API error for mal_id=#{mal_id}: #{inspect(reason)}")
    end
  end

  defp upsert_manga_character(manga_id, entry) do
    character_data = entry["character"] || %{}
    character_mal_id = character_data["mal_id"]
    role = normalize_role(entry["role"])

    case lookup_id("characters", character_mal_id) do
      nil ->
        Logger.warning(
          "[MangaCharactersWorker] Character not found: mal_id=#{character_mal_id}"
        )

      character_id ->
        Repo.insert_all(
          "manga_characters",
          [%{manga_id: manga_id, character_id: character_id, role: role}],
          on_conflict: :nothing
        )
    end
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
