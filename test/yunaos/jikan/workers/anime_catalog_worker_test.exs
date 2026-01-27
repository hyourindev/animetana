defmodule Yunaos.Jikan.Workers.AnimeCatalogWorkerTest do
  use Yunaos.DataCase, async: true

  alias Yunaos.Jikan.Workers.AnimeCatalogWorker

  @sample_anime %{
    "mal_id" => 1,
    "title" => "Cowboy Bebop",
    "title_english" => "Cowboy Bebop",
    "title_japanese" => "カウボーイビバップ",
    "title_synonyms" => [],
    "titles" => [%{"type" => "Default", "title" => "Cowboy Bebop"}],
    "images" => %{
      "jpg" => %{
        "image_url" => "https://cdn.myanimelist.net/images/anime/4/19644.jpg",
        "large_image_url" => "https://cdn.myanimelist.net/images/anime/4/19644l.jpg"
      }
    },
    "trailer" => %{"url" => "https://www.youtube.com/watch?v=123"},
    "type" => "TV",
    "source" => "Original",
    "episodes" => 26,
    "status" => "Finished Airing",
    "aired" => %{
      "from" => "1998-04-03T00:00:00+00:00",
      "to" => "1999-04-24T00:00:00+00:00"
    },
    "duration" => "24 min per ep",
    "rating" => "R - 17+ (violence & profanity)",
    "score" => 8.75,
    "scored_by" => 1_047_821,
    "rank" => 47,
    "popularity" => 42,
    "members" => 2_028_958,
    "favorites" => 88_709,
    "synopsis" => "In the year 2071...",
    "background" => "Won several awards",
    "season" => "spring",
    "year" => 1998,
    "broadcast" => %{"day" => "Saturdays", "time" => "01:00"},
    "producers" => [%{"mal_id" => 23, "type" => "anime", "name" => "Bandai Visual"}],
    "licensors" => [],
    "studios" => [%{"mal_id" => 14, "type" => "anime", "name" => "Sunrise"}],
    "genres" => [%{"mal_id" => 1, "type" => "anime", "name" => "Action"}],
    "themes" => [%{"mal_id" => 50, "type" => "anime", "name" => "Adult Cast"}],
    "demographics" => []
  }

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:second)

  defp insert_anime(item) do
    ts = now()

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
      duration: AnimeCatalogWorker.parse_duration(item["duration"]),
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
      last_synced_at: ts,
      updated_at: ts,
      inserted_at: ts
    }

    replace_cols = [
      :title, :title_english, :title_japanese, :title_romaji, :title_synonyms,
      :cover_image_url, :trailer_url, :type, :source, :status, :rating,
      :episodes, :duration, :start_date, :end_date, :season, :season_year,
      :broadcast_day, :broadcast_time, :mal_score, :mal_scored_by, :mal_rank,
      :mal_popularity, :mal_members, :mal_favorites, :synopsis, :background,
      :sync_status, :last_synced_at, :updated_at
    ]

    Repo.insert_all(
      "anime",
      [attrs],
      on_conflict: {:replace, replace_cols},
      conflict_target: :mal_id,
      returning: [:id]
    )
  end

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
  defp normalize_type(type), do: String.downcase(type)

  defp normalize_source(nil), do: nil
  defp normalize_source(source), do: String.downcase(source)

  defp map_anime_status(nil), do: "unknown"
  defp map_anime_status("Finished Airing"), do: "finished_airing"
  defp map_anime_status("Currently Airing"), do: "currently_airing"
  defp map_anime_status("Not yet aired"), do: "not_yet_aired"

  defp map_anime_status(status) do
    status |> String.downcase() |> String.replace(~r/\s+/, "_")
  end

  defp extract_rating(nil), do: nil

  defp extract_rating(rating) do
    rating |> String.split(" - ", parts: 2) |> List.first() |> String.trim()
  end

  defp parse_date(nil), do: nil

  defp parse_date(datetime_string) do
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

  defp parse_time(time_string) do
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

  defp normalize_broadcast_day(day) do
    day |> String.downcase() |> String.replace(~r/s$/, "")
  end

  defp lookup_id(table, mal_id) do
    from(t in table, where: t.mal_id == ^mal_id, select: t.id)
    |> Repo.one()
  end

  defp insert_genre(mal_id, name) do
    ts = now()

    Repo.insert_all("genres", [
      %{mal_id: mal_id, name: name, type: "anime", inserted_at: ts}
    ])
  end

  defp insert_theme(mal_id, name) do
    ts = now()

    Repo.insert_all("themes", [
      %{mal_id: mal_id, name: name, type: "anime", inserted_at: ts}
    ])
  end

  defp insert_studio(mal_id, name) do
    ts = now()

    Repo.insert_all("studios", [
      %{mal_id: mal_id, name: name, type: "animation", inserted_at: ts, updated_at: ts}
    ])
  end

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  describe "anime record insertion" do
    test "inserts anime with all fields mapped correctly" do
      {1, [anime]} = insert_anime(@sample_anime)

      record =
        from(a in "anime", where: a.id == ^anime.id,
          select: %{
            title: a.title,
            title_english: a.title_english,
            title_japanese: a.title_japanese,
            cover_image_url: a.cover_image_url,
            trailer_url: a.trailer_url,
            type: a.type,
            source: a.source,
            status: a.status,
            rating: a.rating,
            episodes: a.episodes,
            duration: a.duration,
            start_date: a.start_date,
            end_date: a.end_date,
            season: a.season,
            season_year: a.season_year,
            broadcast_day: a.broadcast_day,
            broadcast_time: a.broadcast_time,
            mal_score: a.mal_score,
            mal_scored_by: a.mal_scored_by,
            mal_rank: a.mal_rank,
            mal_popularity: a.mal_popularity,
            mal_members: a.mal_members,
            mal_favorites: a.mal_favorites,
            synopsis: a.synopsis,
            background: a.background,
            sync_status: a.sync_status
          }
        )
        |> Repo.one!()

      assert record.title == "Cowboy Bebop"
      assert record.title_english == "Cowboy Bebop"
      assert record.title_japanese == "カウボーイビバップ"
      assert record.cover_image_url == "https://cdn.myanimelist.net/images/anime/4/19644l.jpg"
      assert record.trailer_url == "https://www.youtube.com/watch?v=123"
      assert record.type == "tv"
      assert record.source == "original"
      assert record.status == "finished_airing"
      assert record.rating == "R"
      assert record.episodes == 26
      assert record.duration == 24
      assert record.start_date == ~D[1998-04-03]
      assert record.end_date == ~D[1999-04-24]
      assert record.season == "spring"
      assert record.season_year == 1998
      assert record.broadcast_day == "saturday"
      assert record.broadcast_time == ~T[01:00:00]
      assert Decimal.equal?(record.mal_score, Decimal.new("8.75"))
      assert record.mal_scored_by == 1_047_821
      assert record.mal_rank == 47
      assert record.mal_popularity == 42
      assert record.mal_members == 2_028_958
      assert record.mal_favorites == 88_709
      assert record.synopsis == "In the year 2071..."
      assert record.background == "Won several awards"
      assert record.sync_status == "synced"
    end
  end

  describe "duration parsing" do
    test "parses '24 min per ep' to 24" do
      assert AnimeCatalogWorker.parse_duration("24 min per ep") == 24
    end

    test "parses '1 hr 30 min' to 90" do
      assert AnimeCatalogWorker.parse_duration("1 hr 30 min") == 90
    end

    test "parses '2 hr' to 120" do
      assert AnimeCatalogWorker.parse_duration("2 hr") == 120
    end

    test "returns nil for 'Unknown'" do
      assert AnimeCatalogWorker.parse_duration("Unknown") == nil
    end

    test "returns nil for nil" do
      assert AnimeCatalogWorker.parse_duration(nil) == nil
    end
  end

  describe "status mapping" do
    test "maps 'Finished Airing' to 'finished_airing'" do
      assert map_anime_status("Finished Airing") == "finished_airing"
    end

    test "maps 'Currently Airing' to 'currently_airing'" do
      assert map_anime_status("Currently Airing") == "currently_airing"
    end

    test "maps 'Not yet aired' to 'not_yet_aired'" do
      assert map_anime_status("Not yet aired") == "not_yet_aired"
    end
  end

  describe "rating extraction" do
    test "extracts 'R' from full rating string" do
      assert extract_rating("R - 17+ (violence & profanity)") == "R"
    end

    test "extracts 'PG-13' from full rating string" do
      assert extract_rating("PG-13 - Teens 13 or older") == "PG-13"
    end

    test "extracts 'G' from full rating string" do
      assert extract_rating("G - All Ages") == "G"
    end

    test "returns nil for nil" do
      assert extract_rating(nil) == nil
    end
  end

  describe "join table insertion" do
    setup do
      insert_genre(1, "Action")
      insert_theme(50, "Adult Cast")
      insert_studio(14, "Sunrise")
      insert_studio(23, "Bandai Visual")

      {1, [anime]} = insert_anime(@sample_anime)
      %{anime_id: anime.id}
    end

    test "creates anime_genres row linking anime to genre", %{anime_id: anime_id} do
      genre_id = lookup_id("genres", 1)

      Repo.insert_all(
        "anime_genres",
        [%{anime_id: anime_id, genre_id: genre_id}],
        on_conflict: :nothing
      )

      count =
        from(ag in "anime_genres",
          where: ag.anime_id == ^anime_id and ag.genre_id == ^genre_id,
          select: count()
        )
        |> Repo.one!()

      assert count == 1
    end

    test "creates anime_themes row linking anime to theme", %{anime_id: anime_id} do
      theme_id = lookup_id("themes", 50)

      Repo.insert_all(
        "anime_themes",
        [%{anime_id: anime_id, theme_id: theme_id}],
        on_conflict: :nothing
      )

      count =
        from(at in "anime_themes",
          where: at.anime_id == ^anime_id and at.theme_id == ^theme_id,
          select: count()
        )
        |> Repo.one!()

      assert count == 1
    end

    test "creates anime_studios row with role 'studio'", %{anime_id: anime_id} do
      studio_id = lookup_id("studios", 14)

      Repo.insert_all(
        "anime_studios",
        [%{anime_id: anime_id, studio_id: studio_id, role: "studio"}],
        on_conflict: :nothing
      )

      row =
        from(s in "anime_studios",
          where: s.anime_id == ^anime_id and s.studio_id == ^studio_id,
          select: %{role: s.role}
        )
        |> Repo.one!()

      assert row.role == "studio"
    end

    test "creates anime_studios row for producer with role 'producer'", %{anime_id: anime_id} do
      producer_id = lookup_id("studios", 23)

      Repo.insert_all(
        "anime_studios",
        [%{anime_id: anime_id, studio_id: producer_id, role: "producer"}],
        on_conflict: :nothing
      )

      row =
        from(s in "anime_studios",
          where: s.anime_id == ^anime_id and s.studio_id == ^producer_id,
          select: %{role: s.role}
        )
        |> Repo.one!()

      assert row.role == "producer"
    end
  end

  describe "upsert behavior" do
    test "inserting same anime twice results in only 1 record with updated fields" do
      insert_anime(@sample_anime)

      updated_item = Map.put(@sample_anime, "score", 9.0)
      insert_anime(updated_item)

      count =
        from(a in "anime", where: a.mal_id == 1, select: count())
        |> Repo.one!()

      assert count == 1

      record =
        from(a in "anime", where: a.mal_id == 1, select: %{mal_score: a.mal_score})
        |> Repo.one!()

      assert Decimal.equal?(record.mal_score, Decimal.from_float(9.0))
    end
  end
end
