defmodule Yunaos.Jikan.Workers.AnimeCatalogWorker do
  @moduledoc """
  Phase 2 worker: Paginates through the entire Jikan anime catalog
  (`GET /anime?page={n}`) and upserts every anime record along with
  its genre, theme, demographic, and studio join-table entries.
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Fetches all pages of the anime catalog and upserts each item."
  def run do
    Logger.info("[AnimeCatalogWorker] Starting anime catalog sync")

    Client.get_all_pages("/anime", [], fn page_data, _page ->
      Logger.info("[AnimeCatalogWorker] Processing page with #{length(page_data)} anime")

      Enum.each(page_data, fn item ->
        try do
          upsert_anime(item)
        rescue
          e ->
            Logger.error(
              "[AnimeCatalogWorker] Failed to upsert anime mal_id=#{item["mal_id"]}: #{inspect(e)}"
            )
        end
      end)

      Process.sleep(1_100)
    end)

    Logger.info("[AnimeCatalogWorker] Anime catalog sync complete")
  end

  # ---------------------------------------------------------------------------
  # Upsert Logic
  # ---------------------------------------------------------------------------

  defp upsert_anime(item) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    attrs = %{
      mal_id: item["mal_id"],
      title: item["title"],
      title_english: item["title_english"],
      title_japanese: item["title_japanese"],
      title_romaji: extract_title_romaji(item),
      title_synonyms: item["title_synonyms"] || [],
      cover_image_url: extract_cover_image(item),
      trailer_url: get_in(item, ["trailer", "url"]),
      type: normalize_type(item["type"]),
      source: normalize_source(item["source"]),
      status: map_anime_status(item["status"]),
      rating: extract_rating(item["rating"]),
      episodes: item["episodes"],
      duration: parse_duration(item["duration"]),
      start_date: parse_date(get_in(item, ["aired", "from"])),
      end_date: parse_date(get_in(item, ["aired", "to"])),
      season: item["season"],
      season_year: item["year"],
      broadcast_day: normalize_broadcast_day(get_in(item, ["broadcast", "day"])),
      broadcast_time: parse_time(get_in(item, ["broadcast", "time"])),
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

    {1, [anime]} =
      Repo.insert_all(
        "anime",
        [attrs],
        on_conflict:
          {:replace,
           [:title, :title_english, :title_japanese, :title_romaji, :title_synonyms,
            :cover_image_url, :trailer_url, :type, :source, :status, :rating,
            :episodes, :duration, :start_date, :end_date, :season, :season_year,
            :broadcast_day, :broadcast_time, :mal_score, :mal_scored_by, :mal_rank,
            :mal_popularity, :mal_members, :mal_favorites, :synopsis, :background,
            :sync_status, :last_synced_at, :updated_at]},
        conflict_target: :mal_id,
        returning: [:id]
      )

    anime_id = anime.id

    upsert_genres(anime_id, item["genres"] || [])
    upsert_themes(anime_id, item["themes"] || [])
    upsert_demographics(anime_id, item["demographics"] || [])
    upsert_studios(anime_id, item)

    Logger.debug("[AnimeCatalogWorker] Upserted anime mal_id=#{item["mal_id"]} -> id=#{anime_id}")
  end

  # ---------------------------------------------------------------------------
  # Join Table Upserts
  # ---------------------------------------------------------------------------

  defp upsert_genres(anime_id, genres) do
    Enum.each(genres, fn genre_data ->
      case lookup_id("genres", genre_data["mal_id"]) do
        nil ->
          Logger.warning("[AnimeCatalogWorker] Genre not found: mal_id=#{genre_data["mal_id"]}")

        genre_id ->
          Repo.insert_all(
            "anime_genres",
            [%{anime_id: anime_id, genre_id: genre_id}],
            on_conflict: :nothing
          )
      end
    end)
  end

  defp upsert_themes(anime_id, themes) do
    Enum.each(themes, fn theme_data ->
      case lookup_id("themes", theme_data["mal_id"]) do
        nil ->
          Logger.warning("[AnimeCatalogWorker] Theme not found: mal_id=#{theme_data["mal_id"]}")

        theme_id ->
          Repo.insert_all(
            "anime_themes",
            [%{anime_id: anime_id, theme_id: theme_id}],
            on_conflict: :nothing
          )
      end
    end)
  end

  defp upsert_demographics(anime_id, demographics) do
    Enum.each(demographics, fn demo_data ->
      case lookup_id("demographics", demo_data["mal_id"]) do
        nil ->
          Logger.warning(
            "[AnimeCatalogWorker] Demographic not found: mal_id=#{demo_data["mal_id"]}"
          )

        demo_id ->
          Repo.insert_all(
            "anime_demographics",
            [%{anime_id: anime_id, demographic_id: demo_id}],
            on_conflict: :nothing
          )
      end
    end)
  end

  defp upsert_studios(anime_id, item) do
    studios = item["studios"] || []
    producers = item["producers"] || []
    licensors = item["licensors"] || []

    upsert_studio_entries(anime_id, studios, "studio")
    upsert_studio_entries(anime_id, producers, "producer")
    upsert_studio_entries(anime_id, licensors, "licensor")
  end

  defp upsert_studio_entries(anime_id, entries, role) do
    Enum.each(entries, fn entry ->
      case lookup_id("studios", entry["mal_id"]) do
        nil ->
          Logger.warning(
            "[AnimeCatalogWorker] Studio not found: mal_id=#{entry["mal_id"]} (#{role})"
          )

        studio_id ->
          Repo.insert_all(
            "anime_studios",
            [%{anime_id: anime_id, studio_id: studio_id, role: role}],
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

  defp normalize_source(nil), do: nil

  defp normalize_source(source) when is_binary(source) do
    String.downcase(source)
  end

  defp map_anime_status(nil), do: "unknown"
  defp map_anime_status("Finished Airing"), do: "finished_airing"
  defp map_anime_status("Currently Airing"), do: "currently_airing"
  defp map_anime_status("Not yet aired"), do: "not_yet_aired"

  defp map_anime_status(status) do
    status
    |> String.downcase()
    |> String.replace(~r/\s+/, "_")
  end

  defp extract_rating(nil), do: nil

  defp extract_rating(rating) when is_binary(rating) do
    rating
    |> String.split(" - ", parts: 2)
    |> List.first()
    |> String.trim()
  end

  @doc false
  def parse_duration(nil), do: nil

  def parse_duration(duration) when is_binary(duration) do
    cond do
      Regex.match?(~r/(\d+)\s*hr/i, duration) && Regex.match?(~r/(\d+)\s*min/i, duration) ->
        [_, hours] = Regex.run(~r/(\d+)\s*hr/i, duration)
        [_, mins] = Regex.run(~r/(\d+)\s*min/i, duration)
        String.to_integer(hours) * 60 + String.to_integer(mins)

      Regex.match?(~r/(\d+)\s*hr/i, duration) ->
        [_, hours] = Regex.run(~r/(\d+)\s*hr/i, duration)
        String.to_integer(hours) * 60

      Regex.match?(~r/(\d+)\s*min/i, duration) ->
        [_, mins] = Regex.run(~r/(\d+)\s*min/i, duration)
        String.to_integer(mins)

      Regex.match?(~r/(\d+)\s*sec/i, duration) ->
        1

      true ->
        nil
    end
  end

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

  defp parse_time(nil), do: nil

  defp parse_time(time_string) when is_binary(time_string) do
    case Time.from_iso8601(time_string <> ":00") do
      {:ok, time} -> time
      {:error, _} ->
        case Time.from_iso8601(time_string) do
          {:ok, time} -> time
          {:error, _} -> nil
        end
    end
  end

  defp normalize_broadcast_day(nil), do: nil

  defp normalize_broadcast_day(day) when is_binary(day) do
    day
    |> String.downcase()
    |> String.replace(~r/s$/, "")
  end
end
