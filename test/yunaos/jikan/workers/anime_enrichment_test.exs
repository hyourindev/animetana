defmodule Yunaos.Jikan.Workers.AnimeEnrichmentTest do
  @moduledoc """
  Phase 3 enrichment tests: anime_relations, anime_characters,
  anime_staff, anime_episodes, anime_statistics, anime_pictures,
  and anime_moreinfo.
  """

  use Yunaos.DataCase, async: true

  alias Yunaos.Repo

  import Ecto.Query

  setup do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    # Base anime (mal_id: 1)
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

    # Second anime (mal_id: 5)
    {1, nil} =
      Repo.insert_all("anime", [
        %{
          mal_id: 5,
          title: "Cowboy Bebop: Tengoku no Tobira",
          type: "movie",
          status: "finished_airing",
          inserted_at: now,
          updated_at: now
        }
      ])

    related_anime_id =
      Repo.one(from a in "anime", where: a.mal_id == 5, select: a.id)

    # Manga (mal_id: 174)
    {1, nil} =
      Repo.insert_all("manga", [
        %{
          mal_id: 174,
          title: "Cowboy Bebop",
          type: "manga",
          status: "finished",
          inserted_at: now,
          updated_at: now
        }
      ])

    manga_id =
      Repo.one(from m in "manga", where: m.mal_id == 174, select: m.id)

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
          name: "Koichi Yamadera",
          inserted_at: now,
          updated_at: now
        }
      ])

    person_id =
      Repo.one(from p in "people", where: p.mal_id == 1, select: p.id)

    %{
      now: now,
      anime_id: anime_id,
      related_anime_id: related_anime_id,
      manga_id: manga_id,
      character_id: character_id,
      person_id: person_id
    }
  end

  # ---------------------------------------------------------------------------
  # anime_relations
  # ---------------------------------------------------------------------------

  describe "anime_relations" do
    test "creates anime_relations and anime_manga_relations from relations response", ctx do
      relations = [
        %{
          "relation" => "Side Story",
          "entry" => [%{"mal_id" => 5, "type" => "anime"}]
        },
        %{
          "relation" => "Adaptation",
          "entry" => [%{"mal_id" => 174, "type" => "manga"}]
        }
      ]

      # Process anime-type entries
      Enum.each(relations, fn relation_group ->
        relation_type =
          relation_group["relation"]
          |> String.downcase()
          |> String.replace(~r/\s+/, "_")
          |> String.replace(~r/[^a-z0-9_]/, "")

        entries = relation_group["entry"] || []

        Enum.each(entries, fn entry ->
          case entry["type"] do
            "anime" ->
              related_anime_id =
                Repo.one(from a in "anime", where: a.mal_id == ^entry["mal_id"], select: a.id)

              if related_anime_id do
                Repo.insert_all(
                  "anime_relations",
                  [%{anime_id: ctx.anime_id, related_anime_id: related_anime_id, relation_type: relation_type}],
                  on_conflict: :nothing
                )
              end

            "manga" ->
              manga_id =
                Repo.one(from m in "manga", where: m.mal_id == ^entry["mal_id"], select: m.id)

              if manga_id do
                Repo.insert_all(
                  "anime_manga_relations",
                  [%{anime_id: ctx.anime_id, manga_id: manga_id, relation_type: relation_type}],
                  on_conflict: :nothing
                )
              end

            _ ->
              :skip
          end
        end)
      end)

      # Verify anime_relations
      anime_rels =
        Repo.all(
          from r in "anime_relations",
            where: r.anime_id == ^ctx.anime_id,
            select: %{related_anime_id: r.related_anime_id, relation_type: r.relation_type}
        )

      assert length(anime_rels) == 1
      [rel] = anime_rels
      assert rel.related_anime_id == ctx.related_anime_id
      assert rel.relation_type == "side_story"

      # Verify anime_manga_relations
      manga_rels =
        Repo.all(
          from r in "anime_manga_relations",
            where: r.anime_id == ^ctx.anime_id,
            select: %{manga_id: r.manga_id, relation_type: r.relation_type}
        )

      assert length(manga_rels) == 1
      [mrel] = manga_rels
      assert mrel.manga_id == ctx.manga_id
      assert mrel.relation_type == "adaptation"
    end

    test "on_conflict: :nothing does not error on duplicate anime_relations insert", ctx do
      row = %{
        anime_id: ctx.anime_id,
        related_anime_id: ctx.related_anime_id,
        relation_type: "side_story"
      }

      {1, nil} = Repo.insert_all("anime_relations", [row], on_conflict: :nothing)
      {0, nil} = Repo.insert_all("anime_relations", [row], on_conflict: :nothing)

      count =
        Repo.one(
          from r in "anime_relations",
            where: r.anime_id == ^ctx.anime_id and r.relation_type == "side_story",
            select: count(r.id)
        )

      assert count == 1
    end
  end

  # ---------------------------------------------------------------------------
  # anime_characters
  # ---------------------------------------------------------------------------

  describe "anime_characters" do
    test "creates anime_characters and character_voice_actors rows", ctx do
      characters_response = [
        %{
          "character" => %{"mal_id" => 1},
          "role" => "Main",
          "voice_actors" => [
            %{"person" => %{"mal_id" => 1}, "language" => "Japanese"}
          ]
        }
      ]

      Enum.each(characters_response, fn item ->
        character_mal_id = item["character"]["mal_id"]
        role = String.downcase(item["role"])

        character_id =
          Repo.one(from c in "characters", where: c.mal_id == ^character_mal_id, select: c.id)

        if character_id do
          Repo.insert_all(
            "anime_characters",
            [%{anime_id: ctx.anime_id, character_id: character_id, role: role}],
            on_conflict: :nothing
          )

          Enum.each(item["voice_actors"] || [], fn va ->
            person_mal_id = va["person"]["mal_id"]
            language = String.downcase(va["language"])

            person_id =
              Repo.one(from p in "people", where: p.mal_id == ^person_mal_id, select: p.id)

            if person_id do
              Repo.insert_all(
                "character_voice_actors",
                [%{character_id: character_id, person_id: person_id, anime_id: ctx.anime_id, language: language}],
                on_conflict: :nothing
              )
            end
          end)
        end
      end)

      # Verify anime_characters
      ac_rows =
        Repo.all(
          from ac in "anime_characters",
            where: ac.anime_id == ^ctx.anime_id,
            select: %{character_id: ac.character_id, role: ac.role}
        )

      assert length(ac_rows) == 1
      [ac] = ac_rows
      assert ac.character_id == ctx.character_id
      assert ac.role == "main"

      # Verify character_voice_actors
      va_rows =
        Repo.all(
          from cva in "character_voice_actors",
            where: cva.character_id == ^ctx.character_id and cva.anime_id == ^ctx.anime_id,
            select: %{person_id: cva.person_id, language: cva.language}
        )

      assert length(va_rows) == 1
      [va] = va_rows
      assert va.person_id == ctx.person_id
      assert va.language == "japanese"
    end
  end

  # ---------------------------------------------------------------------------
  # anime_staff
  # ---------------------------------------------------------------------------

  describe "anime_staff" do
    test "creates multiple anime_staff rows from positions array", ctx do
      staff_response = [
        %{
          "person" => %{"mal_id" => 1},
          "positions" => ["Director", "Producer"]
        }
      ]

      Enum.each(staff_response, fn item ->
        person_mal_id = item["person"]["mal_id"]
        positions = item["positions"] || []

        person_id =
          Repo.one(from p in "people", where: p.mal_id == ^person_mal_id, select: p.id)

        if person_id do
          Enum.each(positions, fn position ->
            Repo.insert_all(
              "anime_staff",
              [%{anime_id: ctx.anime_id, person_id: person_id, position: String.downcase(position)}],
              on_conflict: :nothing
            )
          end)
        end
      end)

      staff_rows =
        Repo.all(
          from s in "anime_staff",
            where: s.anime_id == ^ctx.anime_id,
            select: %{person_id: s.person_id, position: s.position},
            order_by: s.position
        )

      assert length(staff_rows) == 2
      positions = Enum.map(staff_rows, & &1.position)
      assert "director" in positions
      assert "producer" in positions
      assert Enum.all?(staff_rows, fn r -> r.person_id == ctx.person_id end)
    end
  end

  # ---------------------------------------------------------------------------
  # anime_episodes
  # ---------------------------------------------------------------------------

  describe "anime_episodes" do
    test "creates episode row with correct fields from episodes response", ctx do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      episodes_response = [
        %{
          "mal_id" => 1,
          "title" => "Asteroid Blues",
          "title_japanese" => "\u30A2\u30B9\u30C6\u30ED\u30A4\u30C9\u30FB\u30D6\u30EB\u30FC\u30B9",
          "title_romanji" => "Asteroid Blues",
          "aired" => "1998-10-24T00:00:00+00:00",
          "score" => 4.34,
          "filler" => false,
          "recap" => false
        }
      ]

      entries =
        Enum.map(episodes_response, fn ep ->
          {:ok, dt, _offset} = DateTime.from_iso8601(ep["aired"])
          aired = DateTime.to_date(dt)

          %{
            anime_id: ctx.anime_id,
            mal_id: ep["mal_id"],
            episode_number: Decimal.new(ep["mal_id"]),
            title: ep["title"],
            title_japanese: ep["title_japanese"],
            title_romaji: ep["title_romanji"],
            aired: aired,
            average_rating: ep["score"],
            is_filler: ep["filler"] || false,
            is_recap: ep["recap"] || false,
            inserted_at: now,
            updated_at: now
          }
        end)

      Repo.insert_all("episodes", entries,
        on_conflict: {:replace_all_except, [:id, :inserted_at]},
        conflict_target: [:anime_id, :episode_number]
      )

      ep_rows =
        Repo.all(
          from e in "episodes",
            where: e.anime_id == ^ctx.anime_id,
            select: %{
              episode_number: e.episode_number,
              title: e.title,
              title_japanese: e.title_japanese,
              title_romaji: e.title_romaji,
              aired: e.aired,
              average_rating: e.average_rating,
              is_filler: e.is_filler,
              is_recap: e.is_recap
            }
        )

      assert length(ep_rows) == 1
      [ep] = ep_rows
      assert Decimal.equal?(ep.episode_number, Decimal.new("1"))
      assert ep.title == "Asteroid Blues"
      assert ep.title_japanese == "\u30A2\u30B9\u30C6\u30ED\u30A4\u30C9\u30FB\u30D6\u30EB\u30FC\u30B9"
      assert ep.aired == ~D[1998-10-24]
      assert Decimal.equal?(ep.average_rating, Decimal.from_float(4.34))
      assert ep.is_filler == false
      assert ep.is_recap == false
    end

    test "upsert: inserting same episode again results in only 1 record", ctx do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      entry = %{
        anime_id: ctx.anime_id,
        mal_id: 1,
        episode_number: Decimal.new(1),
        title: "Asteroid Blues",
        title_japanese: nil,
        title_romaji: nil,
        aired: nil,
        average_rating: nil,
        is_filler: false,
        is_recap: false,
        inserted_at: now,
        updated_at: now
      }

      Repo.insert_all("episodes", [entry],
        on_conflict: {:replace_all_except, [:id, :inserted_at]},
        conflict_target: [:anime_id, :episode_number]
      )

      Repo.insert_all("episodes", [entry],
        on_conflict: {:replace_all_except, [:id, :inserted_at]},
        conflict_target: [:anime_id, :episode_number]
      )

      count =
        Repo.one(
          from e in "episodes",
            where: e.anime_id == ^ctx.anime_id,
            select: count(e.id)
        )

      assert count == 1
    end
  end

  # ---------------------------------------------------------------------------
  # anime_statistics
  # ---------------------------------------------------------------------------

  describe "anime_statistics" do
    test "creates score_distributions rows with scoreable_type anime", ctx do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      scores_response = [
        %{"score" => 1, "votes" => 2441, "percentage" => 0.2},
        %{"score" => 10, "votes" => 362_920, "percentage" => 34.6}
      ]

      entries =
        Enum.map(scores_response, fn score_entry ->
          %{
            scoreable_type: "anime",
            scoreable_id: ctx.anime_id,
            score: score_entry["score"],
            votes: score_entry["votes"],
            percentage: score_entry["percentage"],
            inserted_at: now,
            updated_at: now
          }
        end)

      Repo.insert_all("score_distributions", entries,
        on_conflict: {:replace, [:votes, :percentage, :updated_at]},
        conflict_target: [:scoreable_type, :scoreable_id, :score]
      )

      sd_rows =
        Repo.all(
          from sd in "score_distributions",
            where: sd.scoreable_type == "anime" and sd.scoreable_id == ^ctx.anime_id,
            select: %{score: sd.score, votes: sd.votes, percentage: sd.percentage},
            order_by: sd.score
        )

      assert length(sd_rows) == 2

      [s1, s10] = sd_rows
      assert s1.score == 1
      assert s1.votes == 2441
      assert Decimal.equal?(s1.percentage, Decimal.from_float(0.2))

      assert s10.score == 10
      assert s10.votes == 362_920
      assert Decimal.equal?(s10.percentage, Decimal.from_float(34.6))
    end

    test "upsert: re-insert with different votes updates existing rows", ctx do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      entry = %{
        scoreable_type: "anime",
        scoreable_id: ctx.anime_id,
        score: 1,
        votes: 2441,
        percentage: 0.2,
        inserted_at: now,
        updated_at: now
      }

      Repo.insert_all("score_distributions", [entry],
        on_conflict: {:replace, [:votes, :percentage, :updated_at]},
        conflict_target: [:scoreable_type, :scoreable_id, :score]
      )

      updated_entry = %{entry | votes: 3000, percentage: 0.3}

      Repo.insert_all("score_distributions", [updated_entry],
        on_conflict: {:replace, [:votes, :percentage, :updated_at]},
        conflict_target: [:scoreable_type, :scoreable_id, :score]
      )

      sd_rows =
        Repo.all(
          from sd in "score_distributions",
            where:
              sd.scoreable_type == "anime" and
                sd.scoreable_id == ^ctx.anime_id and
                sd.score == 1,
            select: %{votes: sd.votes, percentage: sd.percentage}
        )

      assert length(sd_rows) == 1
      [row] = sd_rows
      assert row.votes == 3000
      assert Decimal.equal?(row.percentage, Decimal.from_float(0.3))
    end
  end

  # ---------------------------------------------------------------------------
  # anime_pictures
  # ---------------------------------------------------------------------------

  describe "anime_pictures" do
    test "creates pictures row with all 6 URL fields and imageable_type anime", ctx do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      pictures_response = [
        %{
          "jpg" => %{
            "image_url" => "a.jpg",
            "small_image_url" => "a_s.jpg",
            "large_image_url" => "a_l.jpg"
          },
          "webp" => %{
            "image_url" => "a.webp",
            "small_image_url" => "a_s.webp",
            "large_image_url" => "a_l.webp"
          }
        }
      ]

      # Delete existing pictures first (as the worker does)
      Repo.delete_all(
        from(p in "pictures",
          where: p.imageable_type == "anime" and p.imageable_id == ^ctx.anime_id
        )
      )

      entries =
        Enum.map(pictures_response, fn picture ->
          jpg = picture["jpg"] || %{}
          webp = picture["webp"] || %{}

          %{
            imageable_type: "anime",
            imageable_id: ctx.anime_id,
            jpg_image_url: jpg["image_url"],
            jpg_small_image_url: jpg["small_image_url"],
            jpg_large_image_url: jpg["large_image_url"],
            webp_image_url: webp["image_url"],
            webp_small_image_url: webp["small_image_url"],
            webp_large_image_url: webp["large_image_url"],
            inserted_at: now,
            updated_at: now
          }
        end)

      Repo.insert_all("pictures", entries)

      pic_rows =
        Repo.all(
          from p in "pictures",
            where: p.imageable_type == "anime" and p.imageable_id == ^ctx.anime_id,
            select: %{
              jpg_image_url: p.jpg_image_url,
              jpg_small_image_url: p.jpg_small_image_url,
              jpg_large_image_url: p.jpg_large_image_url,
              webp_image_url: p.webp_image_url,
              webp_small_image_url: p.webp_small_image_url,
              webp_large_image_url: p.webp_large_image_url,
              imageable_type: p.imageable_type
            }
        )

      assert length(pic_rows) == 1
      [pic] = pic_rows
      assert pic.imageable_type == "anime"
      assert pic.jpg_image_url == "a.jpg"
      assert pic.jpg_small_image_url == "a_s.jpg"
      assert pic.jpg_large_image_url == "a_l.jpg"
      assert pic.webp_image_url == "a.webp"
      assert pic.webp_small_image_url == "a_s.webp"
      assert pic.webp_large_image_url == "a_l.webp"
    end

    test "re-run deletes old pictures and inserts new ones", ctx do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      # Insert initial picture
      Repo.insert_all("pictures", [
        %{
          imageable_type: "anime",
          imageable_id: ctx.anime_id,
          jpg_image_url: "old.jpg",
          inserted_at: now,
          updated_at: now
        }
      ])

      # Simulate re-run: delete and re-insert
      Repo.delete_all(
        from(p in "pictures",
          where: p.imageable_type == "anime" and p.imageable_id == ^ctx.anime_id
        )
      )

      Repo.insert_all("pictures", [
        %{
          imageable_type: "anime",
          imageable_id: ctx.anime_id,
          jpg_image_url: "new.jpg",
          inserted_at: now,
          updated_at: now
        }
      ])

      pic_rows =
        Repo.all(
          from p in "pictures",
            where: p.imageable_type == "anime" and p.imageable_id == ^ctx.anime_id,
            select: p.jpg_image_url
        )

      assert length(pic_rows) == 1
      assert hd(pic_rows) == "new.jpg"
    end
  end

  # ---------------------------------------------------------------------------
  # anime_moreinfo
  # ---------------------------------------------------------------------------

  describe "anime_moreinfo" do
    test "updates anime record more_info field", ctx do
      moreinfo_response = %{"moreinfo" => "Watch TV series first"}

      moreinfo = moreinfo_response["moreinfo"]

      if is_binary(moreinfo) do
        Repo.update_all(
          from(a in "anime", where: a.id == ^ctx.anime_id),
          set: [more_info: moreinfo]
        )
      end

      [more_info] =
        Repo.all(
          from a in "anime",
            where: a.id == ^ctx.anime_id,
            select: a.more_info
        )

      assert more_info == "Watch TV series first"
    end

    test "nil moreinfo does not update the field", ctx do
      moreinfo_response = %{"moreinfo" => nil}

      moreinfo = moreinfo_response["moreinfo"]

      if is_binary(moreinfo) do
        Repo.update_all(
          from(a in "anime", where: a.id == ^ctx.anime_id),
          set: [more_info: moreinfo]
        )
      end

      [more_info] =
        Repo.all(
          from a in "anime",
            where: a.id == ^ctx.anime_id,
            select: a.more_info
        )

      assert more_info == nil
    end
  end
end
