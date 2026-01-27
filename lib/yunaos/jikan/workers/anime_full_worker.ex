defmodule Yunaos.Jikan.Workers.AnimeFullWorker do
  @moduledoc """
  Phase 3 worker: For each anime in the database, fetches the full anime
  endpoint (`GET /anime/{mal_id}/full`) to enrich the record with additional
  data and store relations (anime-to-anime, anime-to-manga).
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  @rate_limit_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Iterates over all anime and enriches each with full endpoint data."
  def run do
    Logger.info("[AnimeFullWorker] Starting anime full enrichment")

    anime_list = Repo.all(from(a in "anime", select: {a.id, a.mal_id}))
    total = length(anime_list)
    Logger.info("[AnimeFullWorker] Found #{total} anime to enrich")

    anime_list
    |> Enum.with_index(1)
    |> Enum.each(fn {{anime_id, mal_id}, index} ->
      try do
        Logger.info("[AnimeFullWorker] [#{index}/#{total}] Enriching anime mal_id=#{mal_id}")
        process_anime(anime_id, mal_id)
      rescue
        e ->
          Logger.error(
            "[AnimeFullWorker] Failed to enrich anime mal_id=#{mal_id}: #{inspect(e)}"
          )
      end

      Process.sleep(@rate_limit_ms)
    end)

    Logger.info("[AnimeFullWorker] Anime full enrichment complete")
    :ok
  end

  # ---------------------------------------------------------------------------
  # Processing
  # ---------------------------------------------------------------------------

  defp process_anime(anime_id, mal_id) do
    case Client.get("/anime/#{mal_id}/full") do
      {:ok, %{"data" => data}} ->
        update_anime_record(anime_id, data)
        process_relations(anime_id, data["relations"] || [])

      {:error, :not_found} ->
        Logger.warning("[AnimeFullWorker] Anime not found on Jikan: mal_id=#{mal_id}")

      {:error, reason} ->
        Logger.error("[AnimeFullWorker] API error for mal_id=#{mal_id}: #{inspect(reason)}")
    end
  end

  defp update_anime_record(anime_id, data) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    theme = data["theme"] || %{}
    openings = theme["openings"] || []
    endings = theme["endings"] || []

    external =
      (data["external"] || [])
      |> Enum.map(fn entry -> %{"name" => entry["name"], "url" => entry["url"]} end)

    streaming =
      (data["streaming"] || [])
      |> Enum.map(fn entry -> %{"name" => entry["name"], "url" => entry["url"]} end)

    Repo.update_all(
      from(a in "anime", where: a.id == ^anime_id),
      set: [
        opening_themes: openings,
        ending_themes: endings,
        external_links: external,
        streaming_links: streaming,
        updated_at: now
      ]
    )

    Logger.debug("[AnimeFullWorker] Updated anime id=#{anime_id} with enriched data")
  end

  defp process_relations(anime_id, relations) do
    Enum.each(relations, fn relation_group ->
      relation_type = normalize_relation_type(relation_group["relation"])
      entries = relation_group["entry"] || []

      Enum.each(entries, fn entry ->
        process_relation_entry(anime_id, relation_type, entry)
      end)
    end)
  end

  defp process_relation_entry(anime_id, relation_type, %{"type" => "anime", "mal_id" => mal_id}) do
    case lookup_id("anime", mal_id) do
      nil ->
        Logger.debug(
          "[AnimeFullWorker] Related anime not found in DB: mal_id=#{mal_id}, skipping"
        )

      related_anime_id ->
        Repo.insert_all(
          "anime_relations",
          [%{anime_id: anime_id, related_anime_id: related_anime_id, relation_type: relation_type}],
          on_conflict: :nothing
        )
    end
  end

  defp process_relation_entry(anime_id, relation_type, %{"type" => "manga", "mal_id" => mal_id}) do
    case lookup_id("manga", mal_id) do
      nil ->
        Logger.debug(
          "[AnimeFullWorker] Related manga not found in DB: mal_id=#{mal_id}, skipping"
        )

      manga_id ->
        Repo.insert_all(
          "anime_manga_relations",
          [%{anime_id: anime_id, manga_id: manga_id, relation_type: relation_type}],
          on_conflict: :nothing
        )
    end
  end

  defp process_relation_entry(_anime_id, _relation_type, entry) do
    Logger.debug("[AnimeFullWorker] Skipping relation entry of type: #{entry["type"]}")
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp lookup_id(table, mal_id) when is_integer(mal_id) do
    from(t in table, where: t.mal_id == ^mal_id, select: t.id)
    |> Repo.one()
  end

  defp lookup_id(_table, _mal_id), do: nil

  defp normalize_relation_type(nil), do: "other"

  defp normalize_relation_type(relation) when is_binary(relation) do
    relation
    |> String.downcase()
    |> String.replace(~r/\s+/, "_")
    |> String.replace(~r/[^a-z0-9_]/, "")
  end
end
