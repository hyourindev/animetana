defmodule Yunaos.Jikan.Workers.DeepEnrichmentTest do
  @moduledoc """
  Phase 5 enrichment tests: characters_full, people_full,
  people_works, character_pictures, and people_pictures.
  """

  use Yunaos.DataCase, async: true

  alias Yunaos.Repo

  import Ecto.Query

  setup do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    # Anime (mal_id: 1)
    {1, nil} =
      Repo.insert_all("anime", [
        %{
          mal_id: 1,
          title: "Cowboy Bebop",
          type: "tv",
          status: "finished_airing",
          inserted_at: now,
          updated_at: now
        }
      ])

    anime_id =
      Repo.one(from a in "anime", where: a.mal_id == 1, select: a.id)

    # Manga (mal_id: 1)
    {1, nil} =
      Repo.insert_all("manga", [
        %{
          mal_id: 1,
          title: "Cowboy Bebop",
          type: "manga",
          status: "finished",
          inserted_at: now,
          updated_at: now
        }
      ])

    manga_id =
      Repo.one(from m in "manga", where: m.mal_id == 1, select: m.id)

    # Character (mal_id: 1)
    {1, nil} =
      Repo.insert_all("characters", [
        %{
          mal_id: 1,
          name: "Spike Spiegel",
          inserted_at: now,
          updated_at: now
        }
      ])

    character_id =
      Repo.one(from c in "characters", where: c.mal_id == 1, select: c.id)

    # Person (mal_id: 1)
    {1, nil} =
      Repo.insert_all("people", [
        %{
          mal_id: 1,
          name: "Shinichiro Watanabe",
          inserted_at: now,
          updated_at: now
        }
      ])

    person_id =
      Repo.one(from p in "people", where: p.mal_id == 1, select: p.id)

    %{
      now: now,
      anime_id: anime_id,
      manga_id: manga_id,
      character_id: character_id,
      person_id: person_id
    }
  end

  # ---------------------------------------------------------------------------
  # characters_full
  # ---------------------------------------------------------------------------

  describe "characters_full" do
    test "updates character record with enriched fields", ctx do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      data = %{
        "about" => "Spike Spiegel is a tall, lean bounty hunter.",
        "name_kanji" => "\u30B9\u30D1\u30A4\u30AF\u30FB\u30B9\u30D4\u30FC\u30B2\u30EB",
        "nicknames" => ["Swimming Bird"],
        "favorites" => 54321,
        "images" => %{"jpg" => %{"image_url" => "https://example.com/spike.jpg"}}
      }

      from(c in "characters", where: c.id == ^ctx.character_id)
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

      [char] =
        Repo.all(
          from c in "characters",
            where: c.id == ^ctx.character_id,
            select: %{
              about: c.about,
              name_kanji: c.name_kanji,
              nicknames: c.nicknames,
              favorites_count: c.favorites_count,
              image_url: c.image_url
            }
        )

      assert char.about == "Spike Spiegel is a tall, lean bounty hunter."
      assert char.name_kanji == "\u30B9\u30D1\u30A4\u30AF\u30FB\u30B9\u30D4\u30FC\u30B2\u30EB"
      assert char.nicknames == ["Swimming Bird"]
      assert char.favorites_count == 54321
      assert char.image_url == "https://example.com/spike.jpg"
    end

    test "creates anime_characters and manga_characters from full response", ctx do
      anime_entries = [
        %{
          "role" => "Main",
          "anime" => %{"mal_id" => 1}
        }
      ]

      manga_entries = [
        %{
          "role" => "Main",
          "manga" => %{"mal_id" => 1}
        }
      ]

      # Process anime_characters
      Enum.each(anime_entries, fn entry ->
        role = String.downcase(entry["role"])
        anime_mal_id = get_in(entry, ["anime", "mal_id"])

        anime_id =
          Repo.one(from a in "anime", where: a.mal_id == ^anime_mal_id, select: a.id)

        if anime_id do
          Repo.insert_all(
            "anime_characters",
            [%{anime_id: anime_id, character_id: ctx.character_id, role: role}],
            on_conflict: :nothing
          )
        end
      end)

      # Process manga_characters
      Enum.each(manga_entries, fn entry ->
        role = String.downcase(entry["role"])
        manga_mal_id = get_in(entry, ["manga", "mal_id"])

        manga_id =
          Repo.one(from m in "manga", where: m.mal_id == ^manga_mal_id, select: m.id)

        if manga_id do
          Repo.insert_all(
            "manga_characters",
            [%{manga_id: manga_id, character_id: ctx.character_id, role: role}],
            on_conflict: :nothing
          )
        end
      end)

      # Verify anime_characters
      ac_rows =
        Repo.all(
          from ac in "anime_characters",
            where: ac.character_id == ^ctx.character_id,
            select: %{anime_id: ac.anime_id, role: ac.role}
        )

      assert length(ac_rows) == 1
      [ac] = ac_rows
      assert ac.anime_id == ctx.anime_id
      assert ac.role == "main"

      # Verify manga_characters
      mc_rows =
        Repo.all(
          from mc in "manga_characters",
            where: mc.character_id == ^ctx.character_id,
            select: %{manga_id: mc.manga_id, role: mc.role}
        )

      assert length(mc_rows) == 1
      [mc] = mc_rows
      assert mc.manga_id == ctx.manga_id
      assert mc.role == "main"
    end
  end

  # ---------------------------------------------------------------------------
  # people_full
  # ---------------------------------------------------------------------------

  describe "people_full" do
    test "updates person record with enriched fields", ctx do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      data = %{
        "about" => "Shinichiro Watanabe is a Japanese anime director.",
        "given_name" => "Shinichiro",
        "family_name" => "Watanabe",
        "alternate_names" => ["Shinichiru Watanabe"],
        "birthday" => "1965-05-24T00:00:00+00:00",
        "website_url" => "https://example.com",
        "images" => %{"jpg" => %{"image_url" => "https://example.com/watanabe.jpg"}},
        "favorites" => 12345
      }

      birthday =
        case Date.from_iso8601(String.slice(data["birthday"], 0, 10)) do
          {:ok, date} -> date
          {:error, _} -> nil
        end

      from(p in "people", where: p.id == ^ctx.person_id)
      |> Repo.update_all(
        set: [
          about: data["about"],
          given_name: data["given_name"],
          family_name: data["family_name"],
          alternate_names: data["alternate_names"] || [],
          birthday: birthday,
          website_url: data["website_url"],
          image_url: get_in(data, ["images", "jpg", "image_url"]),
          favorites_count: data["favorites"] || 0,
          updated_at: now
        ]
      )

      [person] =
        Repo.all(
          from p in "people",
            where: p.id == ^ctx.person_id,
            select: %{
              about: p.about,
              given_name: p.given_name,
              family_name: p.family_name,
              alternate_names: p.alternate_names,
              birthday: p.birthday,
              website_url: p.website_url,
              image_url: p.image_url,
              favorites_count: p.favorites_count
            }
        )

      assert person.about == "Shinichiro Watanabe is a Japanese anime director."
      assert person.given_name == "Shinichiro"
      assert person.family_name == "Watanabe"
      assert person.alternate_names == ["Shinichiru Watanabe"]
      assert person.birthday == ~D[1965-05-24]
      assert person.website_url == "https://example.com"
      assert person.image_url == "https://example.com/watanabe.jpg"
      assert person.favorites_count == 12345
    end

    test "creates anime_staff from people full anime array", ctx do
      anime_entries = [
        %{
          "position" => "Director",
          "anime" => %{"mal_id" => 1}
        }
      ]

      Enum.each(anime_entries, fn entry ->
        position = String.downcase(entry["position"])
        anime_mal_id = get_in(entry, ["anime", "mal_id"])

        anime_id =
          Repo.one(from a in "anime", where: a.mal_id == ^anime_mal_id, select: a.id)

        if anime_id do
          Repo.insert_all(
            "anime_staff",
            [%{anime_id: anime_id, person_id: ctx.person_id, position: position}],
            on_conflict: :nothing
          )
        end
      end)

      staff_rows =
        Repo.all(
          from s in "anime_staff",
            where: s.person_id == ^ctx.person_id,
            select: %{anime_id: s.anime_id, position: s.position}
        )

      assert length(staff_rows) == 1
      [staff] = staff_rows
      assert staff.anime_id == ctx.anime_id
      assert staff.position == "director"
    end
  end

  # ---------------------------------------------------------------------------
  # people_works
  # ---------------------------------------------------------------------------

  describe "people_works" do
    test "creates anime_staff from anime works", ctx do
      anime_works = [
        %{
          "position" => "Director",
          "anime" => %{"mal_id" => 1}
        }
      ]

      Enum.each(anime_works, fn entry ->
        position = String.downcase(entry["position"])
        anime_mal_id = get_in(entry, ["anime", "mal_id"])

        anime_id =
          Repo.one(from a in "anime", where: a.mal_id == ^anime_mal_id, select: a.id)

        if anime_id do
          Repo.insert_all(
            "anime_staff",
            [%{anime_id: anime_id, person_id: ctx.person_id, position: position}],
            on_conflict: :nothing
          )
        end
      end)

      staff_rows =
        Repo.all(
          from s in "anime_staff",
            where: s.person_id == ^ctx.person_id,
            select: %{anime_id: s.anime_id, position: s.position}
        )

      assert length(staff_rows) == 1
      [staff] = staff_rows
      assert staff.anime_id == ctx.anime_id
      assert staff.position == "director"
    end

    test "creates manga_staff from manga works", ctx do
      manga_works = [
        %{
          "position" => "Story",
          "manga" => %{"mal_id" => 1}
        }
      ]

      Enum.each(manga_works, fn entry ->
        position = String.downcase(entry["position"])
        manga_mal_id = get_in(entry, ["manga", "mal_id"])

        manga_id =
          Repo.one(from m in "manga", where: m.mal_id == ^manga_mal_id, select: m.id)

        if manga_id do
          Repo.insert_all(
            "manga_staff",
            [%{manga_id: manga_id, person_id: ctx.person_id, position: position}],
            on_conflict: :nothing
          )
        end
      end)

      staff_rows =
        Repo.all(
          from s in "manga_staff",
            where: s.person_id == ^ctx.person_id,
            select: %{manga_id: s.manga_id, position: s.position}
        )

      assert length(staff_rows) == 1
      [staff] = staff_rows
      assert staff.manga_id == ctx.manga_id
      assert staff.position == "story"
    end

    test "creates both anime_staff and manga_staff from combined works", ctx do
      anime_works = [
        %{"position" => "Director", "anime" => %{"mal_id" => 1}}
      ]

      manga_works = [
        %{"position" => "Story", "manga" => %{"mal_id" => 1}}
      ]

      # Process anime works
      Enum.each(anime_works, fn entry ->
        position = String.downcase(entry["position"])
        anime_mal_id = get_in(entry, ["anime", "mal_id"])

        anime_id =
          Repo.one(from a in "anime", where: a.mal_id == ^anime_mal_id, select: a.id)

        if anime_id do
          Repo.insert_all(
            "anime_staff",
            [%{anime_id: anime_id, person_id: ctx.person_id, position: position}],
            on_conflict: :nothing
          )
        end
      end)

      # Process manga works
      Enum.each(manga_works, fn entry ->
        position = String.downcase(entry["position"])
        manga_mal_id = get_in(entry, ["manga", "mal_id"])

        manga_id =
          Repo.one(from m in "manga", where: m.mal_id == ^manga_mal_id, select: m.id)

        if manga_id do
          Repo.insert_all(
            "manga_staff",
            [%{manga_id: manga_id, person_id: ctx.person_id, position: position}],
            on_conflict: :nothing
          )
        end
      end)

      anime_staff_count =
        Repo.one(
          from s in "anime_staff",
            where: s.person_id == ^ctx.person_id,
            select: count()
        )

      manga_staff_count =
        Repo.one(
          from s in "manga_staff",
            where: s.person_id == ^ctx.person_id,
            select: count()
        )

      assert anime_staff_count == 1
      assert manga_staff_count == 1
    end
  end

  # ---------------------------------------------------------------------------
  # character_pictures
  # ---------------------------------------------------------------------------

  describe "character_pictures" do
    test "creates pictures row with imageable_type character", ctx do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      pictures_response = [
        %{
          "jpg" => %{
            "image_url" => "c.jpg",
            "small_image_url" => "c_s.jpg",
            "large_image_url" => "c_l.jpg"
          }
        }
      ]

      entries =
        Enum.map(pictures_response, fn pic ->
          jpg = pic["jpg"] || %{}
          large_url = jpg["large_image_url"] || jpg["image_url"]
          small_url = jpg["small_image_url"] || jpg["image_url"]

          %{
            imageable_type: "character",
            imageable_id: ctx.character_id,
            jpg_image_url: large_url,
            jpg_small_image_url: small_url,
            inserted_at: now,
            updated_at: now
          }
        end)
        |> Enum.filter(fn e -> e.jpg_image_url != nil end)

      Repo.insert_all("pictures", entries)

      pic_rows =
        Repo.all(
          from p in "pictures",
            where: p.imageable_type == "character" and p.imageable_id == ^ctx.character_id,
            select: %{
              jpg_image_url: p.jpg_image_url,
              jpg_small_image_url: p.jpg_small_image_url,
              imageable_type: p.imageable_type
            }
        )

      assert length(pic_rows) == 1
      [pic] = pic_rows
      assert pic.imageable_type == "character"
      assert pic.jpg_image_url == "c_l.jpg"
      assert pic.jpg_small_image_url == "c_s.jpg"
    end

    test "re-run deletes old pictures and inserts new ones for character", ctx do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      Repo.insert_all("pictures", [
        %{
          imageable_type: "character",
          imageable_id: ctx.character_id,
          jpg_image_url: "old_char.jpg",
          inserted_at: now,
          updated_at: now
        }
      ])

      Repo.delete_all(
        from(p in "pictures",
          where: p.imageable_type == "character" and p.imageable_id == ^ctx.character_id
        )
      )

      Repo.insert_all("pictures", [
        %{
          imageable_type: "character",
          imageable_id: ctx.character_id,
          jpg_image_url: "new_char.jpg",
          inserted_at: now,
          updated_at: now
        }
      ])

      pic_rows =
        Repo.all(
          from p in "pictures",
            where: p.imageable_type == "character" and p.imageable_id == ^ctx.character_id,
            select: p.jpg_image_url
        )

      assert length(pic_rows) == 1
      assert hd(pic_rows) == "new_char.jpg"
    end
  end

  # ---------------------------------------------------------------------------
  # people_pictures
  # ---------------------------------------------------------------------------

  describe "people_pictures" do
    test "creates pictures row with imageable_type person", ctx do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      pictures_response = [
        %{
          "jpg" => %{
            "image_url" => "p.jpg",
            "small_image_url" => "p_s.jpg",
            "large_image_url" => "p_l.jpg"
          }
        }
      ]

      entries =
        Enum.map(pictures_response, fn pic ->
          jpg = pic["jpg"] || %{}
          large_url = jpg["large_image_url"] || jpg["image_url"]
          small_url = jpg["small_image_url"] || jpg["image_url"]

          %{
            imageable_type: "person",
            imageable_id: ctx.person_id,
            jpg_image_url: large_url,
            jpg_small_image_url: small_url,
            inserted_at: now,
            updated_at: now
          }
        end)
        |> Enum.filter(fn e -> e.jpg_image_url != nil end)

      Repo.insert_all("pictures", entries)

      pic_rows =
        Repo.all(
          from p in "pictures",
            where: p.imageable_type == "person" and p.imageable_id == ^ctx.person_id,
            select: %{
              jpg_image_url: p.jpg_image_url,
              jpg_small_image_url: p.jpg_small_image_url,
              imageable_type: p.imageable_type
            }
        )

      assert length(pic_rows) == 1
      [pic] = pic_rows
      assert pic.imageable_type == "person"
      assert pic.jpg_image_url == "p_l.jpg"
      assert pic.jpg_small_image_url == "p_s.jpg"
    end

    test "re-run deletes old pictures and inserts new ones for person", ctx do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      Repo.insert_all("pictures", [
        %{
          imageable_type: "person",
          imageable_id: ctx.person_id,
          jpg_image_url: "old_person.jpg",
          inserted_at: now,
          updated_at: now
        }
      ])

      Repo.delete_all(
        from(p in "pictures",
          where: p.imageable_type == "person" and p.imageable_id == ^ctx.person_id
        )
      )

      Repo.insert_all("pictures", [
        %{
          imageable_type: "person",
          imageable_id: ctx.person_id,
          jpg_image_url: "new_person.jpg",
          inserted_at: now,
          updated_at: now
        }
      ])

      pic_rows =
        Repo.all(
          from p in "pictures",
            where: p.imageable_type == "person" and p.imageable_id == ^ctx.person_id,
            select: p.jpg_image_url
        )

      assert length(pic_rows) == 1
      assert hd(pic_rows) == "new_person.jpg"
    end
  end
end
