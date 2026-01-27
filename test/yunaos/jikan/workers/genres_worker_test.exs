defmodule Yunaos.Jikan.Workers.GenresWorkerTest do
  use Yunaos.DataCase, async: true

  alias Yunaos.JikanFixtures

  @moduledoc """
  Tests for the GenresWorker data processing logic.

  Since the worker calls Client.get/2 directly (no behaviour/mock), we
  replicate the internal merge + upsert logic using fixture data and
  verify the resulting database state.
  """

  # -- helpers that mirror GenresWorker internals --

  defp merge_genres(anime_genres, manga_genres) do
    anime_map =
      anime_genres
      |> Enum.map(fn item -> {item["mal_id"], item["name"]} end)
      |> Map.new()

    manga_map =
      manga_genres
      |> Enum.map(fn item -> {item["mal_id"], item["name"]} end)
      |> Map.new()

    all_ids = MapSet.union(MapSet.new(Map.keys(anime_map)), MapSet.new(Map.keys(manga_map)))

    Enum.map(all_ids, fn mal_id ->
      in_anime = Map.has_key?(anime_map, mal_id)
      in_manga = Map.has_key?(manga_map, mal_id)

      type =
        cond do
          in_anime and in_manga -> "both"
          in_anime -> "anime"
          true -> "manga"
        end

      name = Map.get(anime_map, mal_id) || Map.get(manga_map, mal_id)
      {mal_id, name, type}
    end)
  end

  defp upsert_genres(merged) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries =
      Enum.map(merged, fn {mal_id, name, type} ->
        %{mal_id: mal_id, name: name, type: type, inserted_at: now}
      end)

    entries
    |> Enum.chunk_every(50)
    |> Enum.each(fn batch ->
      Repo.insert_all("genres", batch,
        on_conflict: {:replace, [:name, :type]},
        conflict_target: :mal_id
      )
    end)

    entries
  end

  # -- tests --

  describe "merge_genres/2" do
    test "marks genre present in both anime and manga as 'both'" do
      anime_data = JikanFixtures.genre_anime_response()["data"]
      manga_data = JikanFixtures.genre_manga_response()["data"]

      merged = merge_genres(anime_data, manga_data)

      action = Enum.find(merged, fn {mal_id, _, _} -> mal_id == 1 end)
      assert {1, "Action", "both"} = action
    end

    test "marks anime-only genre as 'anime'" do
      anime_data = JikanFixtures.genre_anime_response()["data"]
      manga_data = JikanFixtures.genre_manga_response()["data"]

      merged = merge_genres(anime_data, manga_data)

      adventure = Enum.find(merged, fn {mal_id, _, _} -> mal_id == 2 end)
      assert {2, "Adventure", "anime"} = adventure
    end

    test "marks manga-only genre as 'manga'" do
      anime_data = JikanFixtures.genre_anime_response()["data"]
      manga_data = JikanFixtures.genre_manga_response()["data"]

      merged = merge_genres(anime_data, manga_data)

      shoujo = Enum.find(merged, fn {mal_id, _, _} -> mal_id == 25 end)
      assert {25, "Shoujo", "manga"} = shoujo
    end

    test "returns correct total count of unique genres" do
      anime_data = JikanFixtures.genre_anime_response()["data"]
      manga_data = JikanFixtures.genre_manga_response()["data"]

      merged = merge_genres(anime_data, manga_data)

      # mal_id 1 (both), 2 (anime-only), 25 (manga-only) = 3 unique
      assert length(merged) == 3
    end

    test "handles empty anime genre list" do
      manga_data = JikanFixtures.genre_manga_response()["data"]
      merged = merge_genres([], manga_data)

      assert length(merged) == 2
      assert Enum.all?(merged, fn {_, _, type} -> type == "manga" end)
    end

    test "handles empty manga genre list" do
      anime_data = JikanFixtures.genre_anime_response()["data"]
      merged = merge_genres(anime_data, [])

      assert length(merged) == 2
      assert Enum.all?(merged, fn {_, _, type} -> type == "anime" end)
    end

    test "handles both lists empty" do
      assert merge_genres([], []) == []
    end
  end

  describe "genre upsert into database" do
    test "inserts genres into the genres table" do
      anime_data = JikanFixtures.genre_anime_response()["data"]
      manga_data = JikanFixtures.genre_manga_response()["data"]

      merged = merge_genres(anime_data, manga_data)
      upsert_genres(merged)

      rows = Repo.all(from(g in "genres", select: %{mal_id: g.mal_id, name: g.name, type: g.type}))

      assert length(rows) == 3
      assert Enum.find(rows, &(&1.mal_id == 1)).type == "both"
      assert Enum.find(rows, &(&1.mal_id == 2)).type == "anime"
      assert Enum.find(rows, &(&1.mal_id == 25)).type == "manga"
    end

    test "upsert updates existing genres on conflict" do
      anime_data = JikanFixtures.genre_anime_response()["data"]

      # First insert: anime-only
      first_merged = merge_genres(anime_data, [])
      upsert_genres(first_merged)

      action_row =
        Repo.one(from(g in "genres", where: g.mal_id == 1, select: %{type: g.type}))

      assert action_row.type == "anime"

      # Second insert: now with manga too -> should become "both"
      manga_data = JikanFixtures.genre_manga_response()["data"]
      second_merged = merge_genres(anime_data, manga_data)
      upsert_genres(second_merged)

      updated_row =
        Repo.one(from(g in "genres", where: g.mal_id == 1, select: %{type: g.type}))

      assert updated_row.type == "both"
    end

    test "upsert does not duplicate rows" do
      anime_data = JikanFixtures.genre_anime_response()["data"]
      manga_data = JikanFixtures.genre_manga_response()["data"]

      merged = merge_genres(anime_data, manga_data)
      upsert_genres(merged)
      upsert_genres(merged)

      count = Repo.one(from(g in "genres", select: count(g.id)))
      assert count == 3
    end
  end
end
