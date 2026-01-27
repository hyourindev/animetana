defmodule Yunaos.Jikan.Workers.MagazinesWorkerTest do
  use Yunaos.DataCase, async: true

  alias Yunaos.JikanFixtures

  @moduledoc """
  Tests for the MagazinesWorker data processing logic.

  Replicates the worker's internal mapping and upsert logic using fixture
  data, then asserts the resulting database state.
  """

  # -- helpers that mirror MagazinesWorker internals --

  defp map_magazine(item) do
    mal_id = item["mal_id"]
    name = item["name"]

    if is_nil(mal_id) or is_nil(name) do
      nil
    else
      %{
        mal_id: mal_id,
        name: name,
        url: item["url"],
        count: item["count"] || 0
      }
    end
  end

  defp process_and_upsert(items) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries =
      items
      |> Enum.map(&map_magazine/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn entry -> Map.merge(entry, %{inserted_at: now, updated_at: now}) end)

    entries
    |> Enum.chunk_every(50)
    |> Enum.each(fn batch ->
      Repo.insert_all("magazines", batch,
        on_conflict: {:replace, [:name, :url, :count, :updated_at]},
        conflict_target: :mal_id
      )
    end)

    entries
  end

  # -- tests --

  describe "map_magazine/1" do
    test "maps all fields from API data" do
      item = List.first(JikanFixtures.magazines_page_response()["data"])
      magazine = map_magazine(item)

      assert magazine.mal_id == 1
      assert magazine.name == "Big Comic Original"
      assert magazine.url == "https://myanimelist.net/manga/magazine/1/Big_Comic_Original"
      assert magazine.count == 101
    end

    test "defaults count to 0 when nil" do
      item = %{"mal_id" => 99, "name" => "Test Magazine", "url" => "https://example.com", "count" => nil}
      magazine = map_magazine(item)

      assert magazine.count == 0
    end

    test "returns nil for item with missing mal_id" do
      item = %{"mal_id" => nil, "name" => "Test", "url" => nil, "count" => 0}
      assert map_magazine(item) == nil
    end

    test "returns nil for item with missing name" do
      item = %{"mal_id" => 1, "name" => nil, "url" => nil, "count" => 0}
      assert map_magazine(item) == nil
    end
  end

  describe "magazine upsert into database" do
    test "inserts magazines into the magazines table" do
      items = JikanFixtures.magazines_multi_response()["data"]
      process_and_upsert(items)

      rows =
        Repo.all(
          from(m in "magazines",
            select: %{mal_id: m.mal_id, name: m.name, url: m.url, count: m.count},
            order_by: m.mal_id
          )
        )

      assert length(rows) == 3

      assert Enum.at(rows, 0).name == "Big Comic Original"
      assert Enum.at(rows, 0).count == 101

      assert Enum.at(rows, 1).name == "Weekly Shounen Jump"
      assert Enum.at(rows, 1).count == 500

      assert Enum.at(rows, 2).name == "Monthly Shounen Magazine"
      assert Enum.at(rows, 2).count == 200
    end

    test "stores url correctly" do
      items = JikanFixtures.magazines_page_response()["data"]
      process_and_upsert(items)

      row =
        Repo.one(
          from(m in "magazines", where: m.mal_id == 1, select: %{url: m.url})
        )

      assert row.url == "https://myanimelist.net/manga/magazine/1/Big_Comic_Original"
    end

    test "upsert updates existing magazine on conflict" do
      items = JikanFixtures.magazines_page_response()["data"]
      process_and_upsert(items)

      row = Repo.one(from(m in "magazines", where: m.mal_id == 1, select: %{count: m.count}))
      assert row.count == 101

      # Update count and re-upsert
      updated_items = [
        %{
          "mal_id" => 1,
          "name" => "Big Comic Original",
          "url" => "https://myanimelist.net/manga/magazine/1/Big_Comic_Original",
          "count" => 150
        }
      ]

      process_and_upsert(updated_items)

      updated_row =
        Repo.one(from(m in "magazines", where: m.mal_id == 1, select: %{count: m.count}))

      assert updated_row.count == 150
    end

    test "upsert updates name on conflict" do
      items = JikanFixtures.magazines_page_response()["data"]
      process_and_upsert(items)

      updated_items = [
        %{
          "mal_id" => 1,
          "name" => "Big Comic Original (Renamed)",
          "url" => "https://myanimelist.net/manga/magazine/1/Big_Comic_Original",
          "count" => 101
        }
      ]

      process_and_upsert(updated_items)

      row = Repo.one(from(m in "magazines", where: m.mal_id == 1, select: %{name: m.name}))
      assert row.name == "Big Comic Original (Renamed)"
    end

    test "upsert does not duplicate rows" do
      items = JikanFixtures.magazines_page_response()["data"]
      process_and_upsert(items)
      process_and_upsert(items)

      count = Repo.one(from(m in "magazines", select: count(m.id)))
      assert count == 1
    end
  end
end
