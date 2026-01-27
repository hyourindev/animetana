defmodule Yunaos.Jikan.Workers.MangaFullWorker do
  @moduledoc """
  Phase 4 worker: Iterates through all manga records and fetches full details
  from `GET /manga/{mal_id}/full`, updating the manga record and upserting
  relation entries into `manga_relations` and `anime_manga_relations`.
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  @rate_limit_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Fetches full details for every manga record."
  def run do
    Logger.info("[MangaFullWorker] Starting manga full enrichment")

    manga_list = Repo.all(from(m in "manga", select: {m.id, m.mal_id}))
    total = length(manga_list)
    Logger.info("[MangaFullWorker] Found #{total} manga to enrich")

    manga_list
    |> Enum.with_index(1)
    |> Enum.each(fn {{id, mal_id}, idx} ->
      try do
        Logger.info("[MangaFullWorker] Processing #{idx}/#{total} mal_id=#{mal_id}")
        process_manga(id, mal_id)
      rescue
        e ->
          Logger.error(
            "[MangaFullWorker] Failed to process manga mal_id=#{mal_id}: #{inspect(e)}"
          )
      end

      Process.sleep(@rate_limit_ms)
    end)

    Logger.info("[MangaFullWorker] Manga full enrichment complete")
  end

  # ---------------------------------------------------------------------------
  # Processing
  # ---------------------------------------------------------------------------

  defp process_manga(manga_id, mal_id) do
    case Client.get("/manga/#{mal_id}/full", []) do
      {:ok, %{"data" => data}} ->
        update_manga(manga_id, data)
        upsert_relations(manga_id, data["relations"] || [])

      {:error, :not_found} ->
        Logger.warning("[MangaFullWorker] Manga not found on Jikan: mal_id=#{mal_id}")

      {:error, reason} ->
        Logger.error("[MangaFullWorker] API error for mal_id=#{mal_id}: #{inspect(reason)}")
    end
  end

  defp update_manga(manga_id, data) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    from(m in "manga", where: m.id == ^manga_id)
    |> Repo.update_all(
      set: [
        synopsis: data["synopsis"],
        background: data["background"],
        sync_status: "enriched",
        last_synced_at: now,
        updated_at: now
      ]
    )
  end

  defp upsert_relations(manga_id, relations) do
    Enum.each(relations, fn relation_group ->
      relation_type = normalize_relation_type(relation_group["relation"])
      entries = relation_group["entry"] || []

      Enum.each(entries, fn entry ->
        entry_mal_id = entry["mal_id"]
        entry_type = String.downcase(entry["type"] || "")

        case entry_type do
          "manga" ->
            case lookup_id("manga", entry_mal_id) do
              nil ->
                Logger.warning(
                  "[MangaFullWorker] Related manga not found: mal_id=#{entry_mal_id}"
                )

              related_manga_id ->
                Repo.insert_all(
                  "manga_relations",
                  [%{manga_id: manga_id, related_manga_id: related_manga_id, relation_type: relation_type}],
                  on_conflict: :nothing
                )
            end

          "anime" ->
            case lookup_id("anime", entry_mal_id) do
              nil ->
                Logger.warning(
                  "[MangaFullWorker] Related anime not found: mal_id=#{entry_mal_id}"
                )

              anime_id ->
                Repo.insert_all(
                  "anime_manga_relations",
                  [%{manga_id: manga_id, anime_id: anime_id, relation_type: relation_type}],
                  on_conflict: :nothing
                )
            end

          _ ->
            Logger.debug("[MangaFullWorker] Skipping unknown relation type: #{entry_type}")
        end
      end)
    end)
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp normalize_relation_type(nil), do: "other"

  defp normalize_relation_type(relation) when is_binary(relation) do
    relation
    |> String.downcase()
    |> String.replace(~r/\s+/, "_")
  end

  defp lookup_id(table, mal_id) when is_integer(mal_id) do
    from(t in table, where: t.mal_id == ^mal_id, select: t.id)
    |> Repo.one()
  end

  defp lookup_id(_table, _mal_id), do: nil
end
