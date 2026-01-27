defmodule Yunaos.Jikan.Workers.MangaCatalogWorkerTest do
  use Yunaos.DataCase, async: true

  @sample_manga %{
    "mal_id" => 1,
    "title" => "Monster",
    "title_english" => "Monster",
    "title_japanese" => "MONSTER",
    "title_synonyms" => [],
    "titles" => [%{"type" => "Default", "title" => "Monster"}],
    "images" => %{
      "jpg" => %{
        "image_url" => "https://cdn.myanimelist.net/images/manga/3/54525.jpg",
        "large_image_url" => "https://cdn.myanimelist.net/images/manga/3/54525l.jpg"
      }
    },
    "type" => "Manga",
    "chapters" => 162,
    "volumes" => 18,
    "status" => "Finished",
    "published" => %{
      "from" => "1994-12-05T00:00:00+00:00",
      "to" => "2001-12-20T00:00:00+00:00"
    },
    "score" => 9.16,
    "scored_by" => 114_393,
    "rank" => 6,
    "popularity" => 27,
    "members" => 284_199,
    "favorites" => 23_456,
    "synopsis" => "Kenzou Tenma is a renowned brain surgeon...",
    "background" => "Won the Tezuka Osamu Cultural Prize",
    "authors" => [%{"mal_id" => 1867, "type" => "people", "name" => "Urasawa, Naoki"}],
    "serializations" => [%{"mal_id" => 1, "type" => "manga", "name" => "Big Comic Original"}],
    "genres" => [%{"mal_id" => 46, "type" => "manga", "name" => "Award Winning"}],
    "themes" => [%{"mal_id" => 40, "type" => "manga", "name" => "Psychological"}],
    "demographics" => [%{"mal_id" => 42, "type" => "manga", "name" => "Seinen"}]
  }

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:second)

  defp insert_manga(item) do
    ts = now()

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
      last_synced_at: ts,
      updated_at: ts,
      inserted_at: ts
    }

    replace_cols = [
      :title, :title_english, :title_japanese, :title_romaji, :title_synonyms,
      :cover_image_url, :type, :status, :chapters, :volumes,
      :published_from, :published_to, :mal_score, :mal_scored_by, :mal_rank,
      :mal_popularity, :mal_members, :mal_favorites, :synopsis, :background,
      :sync_status, :last_synced_at, :updated_at
    ]

    Repo.insert_all(
      "manga",
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

  defp map_manga_status(nil), do: "unknown"
  defp map_manga_status("Finished"), do: "finished"
  defp map_manga_status("Publishing"), do: "publishing"
  defp map_manga_status("On Hiatus"), do: "on_hiatus"
  defp map_manga_status("Discontinued"), do: "discontinued"
  defp map_manga_status("Not yet published"), do: "not_yet_published"

  defp map_manga_status(status) do
    status |> String.downcase() |> String.replace(~r/\s+/, "_")
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

  defp lookup_id(table, mal_id) do
    from(t in table, where: t.mal_id == ^mal_id, select: t.id)
    |> Repo.one()
  end

  defp insert_genre(mal_id, name) do
    ts = now()
    Repo.insert_all("genres", [%{mal_id: mal_id, name: name, type: "manga", inserted_at: ts}])
  end

  defp insert_theme(mal_id, name) do
    ts = now()
    Repo.insert_all("themes", [%{mal_id: mal_id, name: name, type: "manga", inserted_at: ts}])
  end

  defp insert_demographic(mal_id, name) do
    ts = now()

    Repo.insert_all("demographics", [
      %{mal_id: mal_id, name: name, type: "manga", inserted_at: ts}
    ])
  end

  defp insert_magazine(mal_id, name) do
    ts = now()

    Repo.insert_all("magazines", [
      %{mal_id: mal_id, name: name, inserted_at: ts, updated_at: ts}
    ])
  end

  defp insert_person(mal_id, name) do
    ts = now()

    Repo.insert_all("people", [
      %{mal_id: mal_id, name: name, inserted_at: ts, updated_at: ts}
    ])
  end

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  describe "manga record insertion" do
    test "inserts manga with all fields mapped correctly" do
      {1, [manga]} = insert_manga(@sample_manga)

      record =
        from(m in "manga",
          where: m.id == ^manga.id,
          select: %{
            title: m.title,
            title_english: m.title_english,
            title_japanese: m.title_japanese,
            cover_image_url: m.cover_image_url,
            type: m.type,
            status: m.status,
            chapters: m.chapters,
            volumes: m.volumes,
            published_from: m.published_from,
            published_to: m.published_to,
            mal_score: m.mal_score,
            mal_scored_by: m.mal_scored_by,
            mal_rank: m.mal_rank,
            mal_popularity: m.mal_popularity,
            mal_members: m.mal_members,
            mal_favorites: m.mal_favorites,
            synopsis: m.synopsis,
            background: m.background,
            sync_status: m.sync_status
          }
        )
        |> Repo.one!()

      assert record.title == "Monster"
      assert record.title_english == "Monster"
      assert record.title_japanese == "MONSTER"
      assert record.cover_image_url == "https://cdn.myanimelist.net/images/manga/3/54525l.jpg"
      assert record.type == "manga"
      assert record.status == "finished"
      assert record.chapters == 162
      assert record.volumes == 18
      assert record.published_from == ~D[1994-12-05]
      assert record.published_to == ~D[2001-12-20]
      assert Decimal.equal?(record.mal_score, Decimal.new("9.16"))
      assert record.mal_scored_by == 114_393
      assert record.mal_rank == 6
      assert record.mal_popularity == 27
      assert record.mal_members == 284_199
      assert record.mal_favorites == 23_456
      assert record.synopsis == "Kenzou Tenma is a renowned brain surgeon..."
      assert record.background == "Won the Tezuka Osamu Cultural Prize"
      assert record.sync_status == "synced"
    end
  end

  describe "type lowercasing" do
    test "lowercases 'Manga' to 'manga'" do
      assert normalize_type("Manga") == "manga"
    end

    test "lowercases 'Manhwa' to 'manhwa'" do
      assert normalize_type("Manhwa") == "manhwa"
    end

    test "returns 'unknown' for nil" do
      assert normalize_type(nil) == "unknown"
    end
  end

  describe "status mapping" do
    test "maps 'Finished' to 'finished'" do
      assert map_manga_status("Finished") == "finished"
    end

    test "maps 'Publishing' to 'publishing'" do
      assert map_manga_status("Publishing") == "publishing"
    end

    test "maps 'On Hiatus' to 'on_hiatus'" do
      assert map_manga_status("On Hiatus") == "on_hiatus"
    end

    test "maps 'Discontinued' to 'discontinued'" do
      assert map_manga_status("Discontinued") == "discontinued"
    end

    test "maps 'Not yet published' to 'not_yet_published'" do
      assert map_manga_status("Not yet published") == "not_yet_published"
    end
  end

  describe "published dates" do
    test "parses published from and to dates correctly" do
      {1, [manga]} = insert_manga(@sample_manga)

      record =
        from(m in "manga",
          where: m.id == ^manga.id,
          select: %{published_from: m.published_from, published_to: m.published_to}
        )
        |> Repo.one!()

      assert record.published_from == ~D[1994-12-05]
      assert record.published_to == ~D[2001-12-20]
    end
  end

  describe "join tables" do
    setup do
      insert_genre(46, "Award Winning")
      insert_theme(40, "Psychological")
      insert_demographic(42, "Seinen")
      insert_magazine(1, "Big Comic Original")
      insert_person(1867, "Urasawa, Naoki")

      {1, [manga]} = insert_manga(@sample_manga)
      %{manga_id: manga.id}
    end

    test "creates manga_genres row", %{manga_id: manga_id} do
      genre_id = lookup_id("genres", 46)

      Repo.insert_all(
        "manga_genres",
        [%{manga_id: manga_id, genre_id: genre_id}],
        on_conflict: :nothing
      )

      count =
        from(mg in "manga_genres",
          where: mg.manga_id == ^manga_id and mg.genre_id == ^genre_id,
          select: count()
        )
        |> Repo.one!()

      assert count == 1
    end

    test "creates manga_themes row", %{manga_id: manga_id} do
      theme_id = lookup_id("themes", 40)

      Repo.insert_all(
        "manga_themes",
        [%{manga_id: manga_id, theme_id: theme_id}],
        on_conflict: :nothing
      )

      count =
        from(mt in "manga_themes",
          where: mt.manga_id == ^manga_id and mt.theme_id == ^theme_id,
          select: count()
        )
        |> Repo.one!()

      assert count == 1
    end

    test "creates manga_demographics row", %{manga_id: manga_id} do
      demo_id = lookup_id("demographics", 42)

      Repo.insert_all(
        "manga_demographics",
        [%{manga_id: manga_id, demographic_id: demo_id}],
        on_conflict: :nothing
      )

      count =
        from(md in "manga_demographics",
          where: md.manga_id == ^manga_id and md.demographic_id == ^demo_id,
          select: count()
        )
        |> Repo.one!()

      assert count == 1
    end

    test "creates manga_magazines entry from serialization", %{manga_id: manga_id} do
      magazine_id = lookup_id("magazines", 1)

      Repo.insert_all(
        "manga_magazines",
        [%{manga_id: manga_id, magazine_id: magazine_id}],
        on_conflict: :nothing
      )

      count =
        from(mm in "manga_magazines",
          where: mm.manga_id == ^manga_id and mm.magazine_id == ^magazine_id,
          select: count()
        )
        |> Repo.one!()

      assert count == 1
    end

    test "creates manga_staff entry from author", %{manga_id: manga_id} do
      person_id = lookup_id("people", 1867)

      Repo.insert_all(
        "manga_staff",
        [%{manga_id: manga_id, person_id: person_id, position: "story_art"}],
        on_conflict: :nothing
      )

      row =
        from(ms in "manga_staff",
          where: ms.manga_id == ^manga_id and ms.person_id == ^person_id,
          select: %{position: ms.position}
        )
        |> Repo.one!()

      assert row.position == "story_art"
    end
  end

  describe "upsert behavior" do
    test "inserting same manga twice results in only 1 record with updated fields" do
      insert_manga(@sample_manga)

      updated_item = Map.put(@sample_manga, "score", 9.5)
      insert_manga(updated_item)

      count =
        from(m in "manga", where: m.mal_id == 1, select: count())
        |> Repo.one!()

      assert count == 1

      record =
        from(m in "manga", where: m.mal_id == 1, select: %{mal_score: m.mal_score})
        |> Repo.one!()

      assert Decimal.equal?(record.mal_score, Decimal.from_float(9.5))
    end
  end
end
