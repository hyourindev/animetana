defmodule Yunaos.Jikan.Workers.MangaCatalogWorker do
  @moduledoc """
  Phase 2 worker: Paginates through the entire Jikan manga catalog
  (`GET /manga?page={n}`) and upserts every manga record along with
  its genre, theme, demographic, magazine, and staff join-table entries.
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Fetches all pages of the manga catalog and upserts each item."
  def run do
    Logger.info("[MangaCatalogWorker] Starting manga catalog sync")

    Client.get_all_pages("/manga", %{}, fn page_data ->
      Logger.info("[MangaCatalogWorker] Processing page with #{length(page_data)} manga")

      Enum.each(page_data, fn item ->
        try do
          upsert_manga(item)
        rescue
          e ->
            Logger.error(
              "[MangaCatalogWorker] Failed to upsert manga mal_id=#{item["mal_id"]}: #{inspect(e)}"
            )
        end
      end)

      Process.sleep(1_100)
    end)

    Logger.info("[MangaCatalogWorker] Manga catalog sync complete")
  end

  # ---------------------------------------------------------------------------
  # Upsert Logic
  # ---------------------------------------------------------------------------

  defp upsert_manga(item) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    attrs = %{
      mal_id: item["mal_id"],
      title: item["title"],
      title_english: item["title_english"],
      title_japanese: item["title_japanese"],
      title_romaji: extract_title_romaji(item),
      title_synonyms: item["title_synonyms"] || [],
      cover_image_url: extract_cover_image(item),
      type: normalize_type(item["type"]),
      status: map_manga_status(item["status"]),
      chapters: item["chapters"],
      volumes: item["volumes"],
      published_from: parse_date(get_in(item, ["published", "from"])),
      published_to: parse_date(get_in(item, ["published", "to"])),
      mal_score: item["score"],
      mal_scored_by: item["scored_by"],
      mal_rank: item["rank"],
      mal_popularity: item["popularity"],
      mal_members: item["members"],
      mal_favorites: item["favorites"],
      synopsis: item["synopsis"],
      background: item["background"],
      sync_status: "synced",
      last_synced_at: now,
      updated_at: now,
      inserted_at: now
    }

    {1, [manga]} =
      Repo.insert_all(
        "manga",
        [attrs],
        on_conflict: {:replace_all_except, [:id, :inserted_at]},
        conflict_target: :mal_id,
        returning: [:id]
      )

    manga_id = manga.id

    upsert_genres(manga_id, item["genres"] || [])
    upsert_themes(manga_id, item["themes"] || [])
    upsert_demographics(manga_id, item["demographics"] || [])
    upsert_magazines(manga_id, item["serializations"] || [])
    upsert_authors(manga_id, item["authors"] || [])

    Logger.debug("[MangaCatalogWorker] Upserted manga mal_id=#{item["mal_id"]} -> id=#{manga_id}")
  end

  # ---------------------------------------------------------------------------
  # Join Table Upserts
  # ---------------------------------------------------------------------------

  defp upsert_genres(manga_id, genres) do
    Enum.each(genres, fn genre_data ->
      case lookup_id("genres", genre_data["mal_id"]) do
        nil ->
          Logger.warning("[MangaCatalogWorker] Genre not found: mal_id=#{genre_data["mal_id"]}")

        genre_id ->
          Repo.insert_all(
            "manga_genres",
            [%{manga_id: manga_id, genre_id: genre_id}],
            on_conflict: :nothing
          )
      end
    end)
  end

  defp upsert_themes(manga_id, themes) do
    Enum.each(themes, fn theme_data ->
      case lookup_id("themes", theme_data["mal_id"]) do
        nil ->
          Logger.warning("[MangaCatalogWorker] Theme not found: mal_id=#{theme_data["mal_id"]}")

        theme_id ->
          Repo.insert_all(
            "manga_themes",
            [%{manga_id: manga_id, theme_id: theme_id}],
            on_conflict: :nothing
          )
      end
    end)
  end

  defp upsert_demographics(manga_id, demographics) do
    Enum.each(demographics, fn demo_data ->
      case lookup_id("demographics", demo_data["mal_id"]) do
        nil ->
          Logger.warning(
            "[MangaCatalogWorker] Demographic not found: mal_id=#{demo_data["mal_id"]}"
          )

        demo_id ->
          Repo.insert_all(
            "manga_demographics",
            [%{manga_id: manga_id, demographic_id: demo_id}],
            on_conflict: :nothing
          )
      end
    end)
  end

  defp upsert_magazines(manga_id, serializations) do
    Enum.each(serializations, fn serial_data ->
      case lookup_id("magazines", serial_data["mal_id"]) do
        nil ->
          Logger.warning(
            "[MangaCatalogWorker] Magazine not found: mal_id=#{serial_data["mal_id"]}"
          )

        magazine_id ->
          Repo.insert_all(
            "manga_magazines",
            [%{manga_id: manga_id, magazine_id: magazine_id}],
            on_conflict: :nothing
          )
      end
    end)
  end

  defp upsert_authors(manga_id, authors) do
    Enum.each(authors, fn author_data ->
      case lookup_id("people", author_data["mal_id"]) do
        nil ->
          Logger.warning(
            "[MangaCatalogWorker] Person not found: mal_id=#{author_data["mal_id"]}"
          )

        person_id ->
          position = infer_author_position(author_data)

          Repo.insert_all(
            "manga_staff",
            [%{manga_id: manga_id, person_id: person_id, position: position}],
            on_conflict: :nothing
          )
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Lookup Helpers
  # ---------------------------------------------------------------------------

  defp lookup_id(table, mal_id) when is_integer(mal_id) do
    from(t in table, where: t.mal_id == ^mal_id, select: t.id)
    |> Repo.one()
  end

  defp lookup_id(_table, _mal_id), do: nil

  # ---------------------------------------------------------------------------
  # Parsing Helpers
  # ---------------------------------------------------------------------------

  defp extract_title_romaji(item) do
    titles = item["titles"] || []

    default_title =
      Enum.find_value(titles, fn
        %{"type" => "Default", "title" => title} -> title
        _ -> nil
      end)

    if default_title && default_title != item["title"], do: default_title, else: nil
  end

  defp extract_cover_image(item) do
    jpg = get_in(item, ["images", "jpg"]) || %{}
    jpg["large_image_url"] || jpg["image_url"]
  end

  defp normalize_type(nil), do: "unknown"

  defp normalize_type(type) when is_binary(type) do
    String.downcase(type)
  end

  defp map_manga_status(nil), do: "unknown"
  defp map_manga_status("Finished"), do: "finished"
  defp map_manga_status("Publishing"), do: "publishing"
  defp map_manga_status("On Hiatus"), do: "on_hiatus"
  defp map_manga_status("Discontinued"), do: "discontinued"
  defp map_manga_status("Not yet published"), do: "not_yet_published"

  defp map_manga_status(status) do
    status
    |> String.downcase()
    |> String.replace(~r/\s+/, "_")
  end

  defp infer_author_position(%{"name" => name}) when is_binary(name) do
    lower = String.downcase(name)

    cond do
      String.contains?(lower, "(art)") -> "art"
      String.contains?(lower, "(story)") -> "story"
      String.contains?(lower, "(story & art)") -> "story_art"
      true -> "story_art"
    end
  end

  defp infer_author_position(_), do: "story_art"

  defp parse_date(nil), do: nil

  defp parse_date(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, dt, _offset} ->
        DateTime.to_date(dt)

      {:error, _} ->
        case Date.from_iso8601(String.slice(datetime_string, 0, 10)) do
          {:ok, date} -> date
          {:error, _} -> nil
        end
    end
  end
end
