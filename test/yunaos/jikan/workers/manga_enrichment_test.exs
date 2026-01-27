defmodule Yunaos.Jikan.Workers.MangaEnrichmentTest do
  @moduledoc """
  Phase 4 enrichment tests: manga_relations, manga_characters,
  manga_statistics, manga_pictures, and manga_moreinfo.
  """

  use Yunaos.DataCase, async: true

  alias Yunaos.Repo

  import Ecto.Query

  setup do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    # Base manga (mal_id: 1)
    {1, nil} =
      Repo.insert_all("manga", [
        %{
          mal_id: 1,
          title: "Monster",
          type: "manga",
          status: "finished",
          inserted_at: now,
          updated_at: now
        }
      ])

    manga_id =
      Repo.one(from m in "manga", where: m.mal_id == 1, select: m.id)

    # Second manga (mal_id: 10968)
    {1, nil} =
      Repo.insert_all("manga", [
        %{
          mal_id: 10968,
          title: "Another Monster",
          type: "manga",
          status: "finished",
          inserted_at: now,
          updated_at: now
        }
      ])

    related_manga_id =
      Repo.one(from m in "manga", where: m.mal_id == 10968, select: m.id)

    # Anime (mal_id: 19)
    {1, nil} =
      Repo.insert_all("anime", [
        %{
          mal_id: 19,
          title: "Monster",
          type: "tv",
          status: "finished_airing",
          inserted_at: now,
          updated_at: now
        }
      ])

    anime_id =
      Repo.one(from a in "anime", where: a.mal_id == 19, select: a.id)

    # Character (mal_id: 1)
    {1, nil} =
      Repo.insert_all("characters", [
        %{
          mal_id: 1,
          name: "Johan Liebert",
          inserted_at: now,
          updated_at: now
        }
      ])

    character_id =
      Repo.one(from c in "characters", where: c.mal_id == 1, select: c.id)

    %{
      now: now,
      manga_id: manga_id,
      related_manga_id: related_manga_id,
      anime_id: anime_id,
      character_id: character_id
    }
  end

  # ---------------------------------------------------------------------------
  # manga_relations
  # ---------------------------------------------------------------------------

  describe "manga_relations" do
    test "creates anime_manga_relations and manga_relations rows", ctx do
      relations = [
        %{
          "relation" => "Adaptation",
          "entry" => [%{"mal_id" => 19, "type" => "anime"}]
        },
        %{
          "relation" => "Side Story",
          "entry" => [%{"mal_id" => 10968, "type" => "manga"}]
        }
      ]

      Enum.each(relations, fn relation_group ->
        relation_type =
          relation_group["relation"]
          |> String.downcase()
          |> String.replace(~r/\s+/, "_")

        entries = relation_group["entry"] || []

        Enum.each(entries, fn entry ->
          entry_mal_id = entry["mal_id"]
          entry_type = String.downcase(entry["type"] || "")

          case entry_type do
            "manga" ->
              related_manga_id =
                Repo.one(from m in "manga", where: m.mal_id == ^entry_mal_id, select: m.id)

              if related_manga_id do
                Repo.insert_all(
                  "manga_relations",
                  [%{manga_id: ctx.manga_id, related_manga_id: related_manga_id, relation_type: relation_type}],
                  on_conflict: :nothing
                )
              end

            "anime" ->
              anime_id =
                Repo.one(from a in "anime", where: a.mal_id == ^entry_mal_id, select: a.id)

              if anime_id do
                Repo.insert_all(
                  "anime_manga_relations",
                  [%{manga_id: ctx.manga_id, anime_id: anime_id, relation_type: relation_type}],
                  on_conflict: :nothing
                )
              end

            _ ->
              :skip
          end
        end)
      end)

      # Verify anime_manga_relations
      amr_rows =
        Repo.all(
          from r in "anime_manga_relations",
            where: r.manga_id == ^ctx.manga_id,
            select: %{anime_id: r.anime_id, relation_type: r.relation_type}
        )

      assert length(amr_rows) == 1
      [amr] = amr_rows
      assert amr.anime_id == ctx.anime_id
      assert amr.relation_type == "adaptation"

      # Verify manga_relations
      mr_rows =
        Repo.all(
          from r in "manga_relations",
            where: r.manga_id == ^ctx.manga_id,
            select: %{related_manga_id: r.related_manga_id, relation_type: r.relation_type}
        )

      assert length(mr_rows) == 1
      [mr] = mr_rows
      assert mr.related_manga_id == ctx.related_manga_id
      assert mr.relation_type == "side_story"
    end
  end

  # ---------------------------------------------------------------------------
  # manga_characters
  # ---------------------------------------------------------------------------

  describe "manga_characters" do
    test "creates manga_characters row with correct role", ctx do
      characters_response = [
        %{
          "character" => %{"mal_id" => 1},
          "role" => "Main"
        }
      ]

      Enum.each(characters_response, fn entry ->
        character_mal_id = entry["character"]["mal_id"]
        role = String.downcase(entry["role"])

        character_id =
          Repo.one(from c in "characters", where: c.mal_id == ^character_mal_id, select: c.id)

        if character_id do
          Repo.insert_all(
            "manga_characters",
            [%{manga_id: ctx.manga_id, character_id: character_id, role: role}],
            on_conflict: :nothing
          )
        end
      end)

      mc_rows =
        Repo.all(
          from mc in "manga_characters",
            where: mc.manga_id == ^ctx.manga_id,
            select: %{character_id: mc.character_id, role: mc.role}
        )

      assert length(mc_rows) == 1
      [mc] = mc_rows
      assert mc.character_id == ctx.character_id
      assert mc.role == "main"
    end
  end

  # ---------------------------------------------------------------------------
  # manga_statistics
  # ---------------------------------------------------------------------------

  describe "manga_statistics" do
    test "creates score_distributions rows with scoreable_type manga", ctx do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      scores_response = [
        %{"score" => 1, "votes" => 500, "percentage" => 0.5},
        %{"score" => 10, "votes" => 100_000, "percentage" => 45.0}
      ]

      Enum.each(scores_response, fn score_entry ->
        attrs = %{
          scoreable_type: "manga",
          scoreable_id: ctx.manga_id,
          score: score_entry["score"],
          votes: score_entry["votes"],
          percentage: score_entry["percentage"],
          inserted_at: now,
          updated_at: now
        }

        Repo.insert_all("score_distributions", [attrs],
          on_conflict: {:replace, [:votes, :percentage, :updated_at]},
          conflict_target: [:scoreable_type, :scoreable_id, :score]
        )
      end)

      sd_rows =
        Repo.all(
          from sd in "score_distributions",
            where: sd.scoreable_type == "manga" and sd.scoreable_id == ^ctx.manga_id,
            select: %{score: sd.score, votes: sd.votes, percentage: sd.percentage},
            order_by: sd.score
        )

      assert length(sd_rows) == 2

      [s1, s10] = sd_rows
      assert s1.score == 1
      assert s1.votes == 500
      assert Decimal.equal?(s1.percentage, Decimal.from_float(0.5))

      assert s10.score == 10
      assert s10.votes == 100_000
      assert Decimal.equal?(s10.percentage, Decimal.from_float(45.0))
    end

    test "upsert: re-insert with different votes updates existing rows", ctx do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      entry = %{
        scoreable_type: "manga",
        scoreable_id: ctx.manga_id,
        score: 5,
        votes: 1000,
        percentage: 10.0,
        inserted_at: now,
        updated_at: now
      }

      Repo.insert_all("score_distributions", [entry],
        on_conflict: {:replace, [:votes, :percentage, :updated_at]},
        conflict_target: [:scoreable_type, :scoreable_id, :score]
      )

      updated_entry = %{entry | votes: 2000, percentage: 15.0}

      Repo.insert_all("score_distributions", [updated_entry],
        on_conflict: {:replace, [:votes, :percentage, :updated_at]},
        conflict_target: [:scoreable_type, :scoreable_id, :score]
      )

      sd_rows =
        Repo.all(
          from sd in "score_distributions",
            where:
              sd.scoreable_type == "manga" and
                sd.scoreable_id == ^ctx.manga_id and
                sd.score == 5,
            select: %{votes: sd.votes, percentage: sd.percentage}
        )

      assert length(sd_rows) == 1
      [row] = sd_rows
      assert row.votes == 2000
      assert Decimal.equal?(row.percentage, Decimal.from_float(15.0))
    end
  end

  # ---------------------------------------------------------------------------
  # manga_pictures
  # ---------------------------------------------------------------------------

  describe "manga_pictures" do
    test "creates pictures row with imageable_type manga", ctx do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      pictures_response = [
        %{
          "jpg" => %{
            "image_url" => "m.jpg",
            "small_image_url" => "m_s.jpg",
            "large_image_url" => "m_l.jpg"
          }
        }
      ]

      entries =
        Enum.map(pictures_response, fn pic ->
          jpg = pic["jpg"] || %{}
          large_url = jpg["large_image_url"] || jpg["image_url"]
          small_url = jpg["small_image_url"] || jpg["image_url"]

          %{
            imageable_type: "manga",
            imageable_id: ctx.manga_id,
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
            where: p.imageable_type == "manga" and p.imageable_id == ^ctx.manga_id,
            select: %{
              jpg_image_url: p.jpg_image_url,
              jpg_small_image_url: p.jpg_small_image_url,
              imageable_type: p.imageable_type
            }
        )

      assert length(pic_rows) == 1
      [pic] = pic_rows
      assert pic.imageable_type == "manga"
      assert pic.jpg_image_url == "m_l.jpg"
      assert pic.jpg_small_image_url == "m_s.jpg"
    end

    test "re-run deletes old pictures and inserts new ones", ctx do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      # Insert initial picture
      Repo.insert_all("pictures", [
        %{
          imageable_type: "manga",
          imageable_id: ctx.manga_id,
          jpg_image_url: "old_manga.jpg",
          inserted_at: now,
          updated_at: now
        }
      ])

      # Simulate re-run: delete existing then insert new
      Repo.delete_all(
        from(p in "pictures",
          where: p.imageable_type == "manga" and p.imageable_id == ^ctx.manga_id
        )
      )

      Repo.insert_all("pictures", [
        %{
          imageable_type: "manga",
          imageable_id: ctx.manga_id,
          jpg_image_url: "new_manga.jpg",
          inserted_at: now,
          updated_at: now
        }
      ])

      pic_rows =
        Repo.all(
          from p in "pictures",
            where: p.imageable_type == "manga" and p.imageable_id == ^ctx.manga_id,
            select: p.jpg_image_url
        )

      assert length(pic_rows) == 1
      assert hd(pic_rows) == "new_manga.jpg"
    end
  end

  # ---------------------------------------------------------------------------
  # manga_moreinfo
  # ---------------------------------------------------------------------------

  describe "manga_moreinfo" do
    test "updates manga record more_info field", ctx do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      moreinfo = "Read the light novel first"

      from(m in "manga", where: m.id == ^ctx.manga_id)
      |> Repo.update_all(set: [more_info: moreinfo, updated_at: now])

      [more_info] =
        Repo.all(
          from m in "manga",
            where: m.id == ^ctx.manga_id,
            select: m.more_info
        )

      assert more_info == "Read the light novel first"
    end

    test "nil moreinfo does not update the field", ctx do
      moreinfo = nil

      if moreinfo do
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        from(m in "manga", where: m.id == ^ctx.manga_id)
        |> Repo.update_all(set: [more_info: moreinfo, updated_at: now])
      end

      [more_info] =
        Repo.all(
          from m in "manga",
            where: m.id == ^ctx.manga_id,
            select: m.more_info
        )

      assert more_info == nil
    end
  end
end
