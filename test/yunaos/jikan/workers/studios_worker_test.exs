defmodule Yunaos.Jikan.Workers.StudiosWorkerTest do
  use Yunaos.DataCase, async: true

  alias Yunaos.JikanFixtures

  @moduledoc """
  Tests for the StudiosWorker data processing logic.

  Replicates the worker's internal mapping and upsert logic using fixture
  data, then asserts the resulting database state.
  """

  # -- helpers that mirror StudiosWorker internals --

  defp map_studio(item) do
    mal_id = item["mal_id"]

    name =
      item
      |> get_in(["titles"])
      |> find_default_title()

    established = parse_date(item["established"])
    about = item["about"]
    website_url = item["url"]

    if is_nil(mal_id) or is_nil(name) do
      nil
    else
      %{
        mal_id: mal_id,
        name: name,
        type: "studio",
        established: established,
        website_url: website_url,
        about: about
      }
    end
  end

  defp find_default_title(nil), do: nil

  defp find_default_title(titles) do
    case Enum.find(titles, fn t -> t["type"] == "Default" end) do
      nil -> List.first(titles) |> then(fn t -> t && t["title"] end)
      title -> title["title"]
    end
  end

  defp parse_date(nil), do: nil

  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(String.slice(date_string, 0, 10)) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end

  defp parse_date(_), do: nil

  defp process_and_upsert(items) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries =
      items
      |> Enum.map(&map_studio/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn entry -> Map.merge(entry, %{inserted_at: now, updated_at: now}) end)

    entries
    |> Enum.chunk_every(50)
    |> Enum.each(fn batch ->
      Repo.insert_all("studios", batch,
        on_conflict:
          {:replace, [:name, :type, :established, :website_url, :about, :updated_at]},
        conflict_target: :mal_id
      )
    end)

    entries
  end

  # -- tests --

  describe "map_studio/1" do
    test "extracts Default title as name" do
      item = List.first(JikanFixtures.producers_page_response()["data"])
      studio = map_studio(item)

      assert studio.name == "Studio Pierrot"
    end

    test "falls back to first title when no Default type exists" do
      items = JikanFixtures.producers_multi_response()["data"]
      # Third item has only a Japanese title, no Default
      item = Enum.at(items, 2)
      studio = map_studio(item)

      assert studio.name == "無名スタジオ"
    end

    test "parses established date correctly" do
      item = List.first(JikanFixtures.producers_page_response()["data"])
      studio = map_studio(item)

      assert studio.established == ~D[1979-05-01]
    end

    test "handles nil established date" do
      items = JikanFixtures.producers_multi_response()["data"]
      item = Enum.at(items, 2)
      studio = map_studio(item)

      assert studio.established == nil
    end

    test "extracts url as website_url" do
      item = List.first(JikanFixtures.producers_page_response()["data"])
      studio = map_studio(item)

      assert studio.website_url == "https://myanimelist.net/anime/producer/1"
    end

    test "sets type to 'studio'" do
      item = List.first(JikanFixtures.producers_page_response()["data"])
      studio = map_studio(item)

      assert studio.type == "studio"
    end

    test "returns nil for item with missing mal_id" do
      item = %{
        "mal_id" => nil,
        "titles" => [%{"type" => "Default", "title" => "Test"}],
        "established" => nil,
        "about" => nil,
        "url" => nil
      }

      assert map_studio(item) == nil
    end

    test "returns nil for item with no titles" do
      item = %{
        "mal_id" => 99,
        "titles" => nil,
        "established" => nil,
        "about" => nil,
        "url" => nil
      }

      assert map_studio(item) == nil
    end
  end

  describe "studio upsert into database" do
    test "inserts studios into the studios table" do
      items = JikanFixtures.producers_multi_response()["data"]
      process_and_upsert(items)

      rows =
        Repo.all(
          from(s in "studios",
            select: %{mal_id: s.mal_id, name: s.name, type: s.type, established: s.established},
            order_by: s.mal_id
          )
        )

      assert length(rows) == 3

      assert Enum.at(rows, 0).name == "Studio Pierrot"
      assert Enum.at(rows, 0).established == ~D[1979-05-01]

      assert Enum.at(rows, 1).name == "Kyoto Animation"
      assert Enum.at(rows, 1).established == ~D[1981-07-12]

      assert Enum.at(rows, 2).name == "無名スタジオ"
      assert Enum.at(rows, 2).established == nil
    end

    test "upsert updates existing studio on conflict" do
      items = JikanFixtures.producers_page_response()["data"]
      process_and_upsert(items)

      row = Repo.one(from(s in "studios", where: s.mal_id == 1, select: %{about: s.about}))
      assert row.about == "Studio Pierrot Co."

      # Update the about field and re-upsert
      updated_items = [
        %{
          "mal_id" => 1,
          "url" => "https://myanimelist.net/anime/producer/1",
          "titles" => [%{"type" => "Default", "title" => "Studio Pierrot"}],
          "established" => "1979-05-01T00:00:00+00:00",
          "about" => "Updated description",
          "count" => 400
        }
      ]

      process_and_upsert(updated_items)

      updated_row =
        Repo.one(from(s in "studios", where: s.mal_id == 1, select: %{about: s.about}))

      assert updated_row.about == "Updated description"
    end

    test "upsert does not duplicate rows" do
      items = JikanFixtures.producers_page_response()["data"]
      process_and_upsert(items)
      process_and_upsert(items)

      count = Repo.one(from(s in "studios", select: count(s.id)))
      assert count == 1
    end
  end
end
