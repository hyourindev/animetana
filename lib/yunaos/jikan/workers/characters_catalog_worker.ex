defmodule Yunaos.Jikan.Workers.CharactersCatalogWorker do
  @moduledoc """
  Phase 2 worker: Paginates through the entire Jikan character catalog
  (`GET /characters?page={n}`) and upserts every character record.
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Fetches all pages of the character catalog and upserts each item."
  def run do
    Logger.info("[CharactersCatalogWorker] Starting character catalog sync")

    Client.get_all_pages("/characters", [], fn page_data, _page ->
      Logger.info("[CharactersCatalogWorker] Processing page with #{length(page_data)} characters")

      Enum.each(page_data, fn item ->
        try do
          upsert_character(item)
        rescue
          e ->
            Logger.error(
              "[CharactersCatalogWorker] Failed to upsert character mal_id=#{item["mal_id"]}: #{inspect(e)}"
            )
        end
      end)

      Process.sleep(1_100)
    end)

    Logger.info("[CharactersCatalogWorker] Character catalog sync complete")
  end

  # ---------------------------------------------------------------------------
  # Upsert Logic
  # ---------------------------------------------------------------------------

  defp upsert_character(item) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    attrs = %{
      mal_id: item["mal_id"],
      name: item["name"],
      name_kanji: item["name_kanji"],
      nicknames: item["nicknames"] || [],
      about: item["about"],
      image_url: extract_image_url(item),
      favorites_count: item["favorites"] || 0,
      updated_at: now,
      inserted_at: now
    }

    Repo.insert_all(
      "characters",
      [attrs],
      on_conflict:
        {:replace,
         [:name, :name_kanji, :nicknames, :about, :image_url,
          :favorites_count, :updated_at]},
      conflict_target: :mal_id
    )

    Logger.debug("[CharactersCatalogWorker] Upserted character mal_id=#{item["mal_id"]}")
  end

  # ---------------------------------------------------------------------------
  # Parsing Helpers
  # ---------------------------------------------------------------------------

  defp extract_image_url(item) do
    get_in(item, ["images", "jpg", "image_url"])
  end
end
