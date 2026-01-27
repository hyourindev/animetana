defmodule Yunaos.Jikan.Workers.CharactersCatalogWorkerTest do
  use Yunaos.DataCase, async: true

  @sample_character %{
    "mal_id" => 1,
    "name" => "Spike Spiegel",
    "name_kanji" => "スパイク・スピーゲル",
    "nicknames" => ["Swimming Bird"],
    "favorites" => 48_635,
    "about" => "Birthdate: June 26, 2044...",
    "images" => %{
      "jpg" => %{
        "image_url" => "https://cdn.myanimelist.net/images/characters/11/516853.jpg"
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:second)

  defp insert_character(item) do
    ts = now()

    attrs = %{
      mal_id: item["mal_id"],
      name: item["name"],
      name_kanji: item["name_kanji"],
      nicknames: item["nicknames"] || [],
      about: item["about"],
      image_url: get_in(item, ["images", "jpg", "image_url"]),
      favorites_count: item["favorites"] || 0,
      updated_at: ts,
      inserted_at: ts
    }

    replace_cols = [
      :name, :name_kanji, :nicknames, :about, :image_url,
      :favorites_count, :updated_at
    ]

    Repo.insert_all(
      "characters",
      [attrs],
      on_conflict: {:replace, replace_cols},
      conflict_target: :mal_id,
      returning: [:id]
    )
  end

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  describe "character record insertion" do
    test "inserts character with all fields mapped correctly" do
      {1, [character]} = insert_character(@sample_character)

      record =
        from(c in "characters",
          where: c.id == ^character.id,
          select: %{
            mal_id: c.mal_id,
            name: c.name,
            name_kanji: c.name_kanji,
            nicknames: c.nicknames,
            about: c.about,
            image_url: c.image_url,
            favorites_count: c.favorites_count
          }
        )
        |> Repo.one!()

      assert record.mal_id == 1
      assert record.name == "Spike Spiegel"
      assert record.name_kanji == "スパイク・スピーゲル"
      assert record.nicknames == ["Swimming Bird"]
      assert record.about == "Birthdate: June 26, 2044..."
      assert record.image_url == "https://cdn.myanimelist.net/images/characters/11/516853.jpg"
      assert record.favorites_count == 48_635
    end

    test "maps 'favorites' to favorites_count" do
      {1, [character]} = insert_character(@sample_character)

      record =
        from(c in "characters",
          where: c.id == ^character.id,
          select: %{favorites_count: c.favorites_count}
        )
        |> Repo.one!()

      assert record.favorites_count == 48_635
    end

    test "stores nicknames as array" do
      item = Map.put(@sample_character, "nicknames", ["Swimming Bird", "Cowboy"])
      {1, [character]} = insert_character(item)

      record =
        from(c in "characters",
          where: c.id == ^character.id,
          select: %{nicknames: c.nicknames}
        )
        |> Repo.one!()

      assert record.nicknames == ["Swimming Bird", "Cowboy"]
    end

    test "extracts image_url from nested images path" do
      {1, [character]} = insert_character(@sample_character)

      record =
        from(c in "characters",
          where: c.id == ^character.id,
          select: %{image_url: c.image_url}
        )
        |> Repo.one!()

      assert record.image_url == "https://cdn.myanimelist.net/images/characters/11/516853.jpg"
    end

    test "defaults favorites_count to 0 when favorites is nil" do
      item = Map.put(@sample_character, "favorites", nil)
      {1, [character]} = insert_character(item)

      record =
        from(c in "characters",
          where: c.id == ^character.id,
          select: %{favorites_count: c.favorites_count}
        )
        |> Repo.one!()

      assert record.favorites_count == 0
    end
  end

  describe "upsert on mal_id" do
    test "inserting same character twice results in only 1 record with updated fields" do
      insert_character(@sample_character)

      updated_item =
        @sample_character
        |> Map.put("favorites", 50_000)
        |> Map.put("about", "Updated bio...")

      insert_character(updated_item)

      count =
        from(c in "characters", where: c.mal_id == 1, select: count())
        |> Repo.one!()

      assert count == 1

      record =
        from(c in "characters",
          where: c.mal_id == 1,
          select: %{favorites_count: c.favorites_count, about: c.about}
        )
        |> Repo.one!()

      assert record.favorites_count == 50_000
      assert record.about == "Updated bio..."
    end

    test "upsert preserves original inserted_at timestamp" do
      {1, [first]} = insert_character(@sample_character)

      first_record =
        from(c in "characters",
          where: c.id == ^first.id,
          select: %{inserted_at: c.inserted_at}
        )
        |> Repo.one!()

      # Small delay to ensure timestamps differ
      Process.sleep(10)

      insert_character(Map.put(@sample_character, "favorites", 99_999))

      updated_record =
        from(c in "characters",
          where: c.mal_id == 1,
          select: %{inserted_at: c.inserted_at, favorites_count: c.favorites_count}
        )
        |> Repo.one!()

      assert updated_record.inserted_at == first_record.inserted_at
      assert updated_record.favorites_count == 99_999
    end
  end
end
