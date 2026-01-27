defmodule Yunaos.Jikan.Workers.PeopleWorkerTest do
  use Yunaos.DataCase, async: true

  alias Yunaos.JikanFixtures

  @moduledoc """
  Tests for the PeopleWorker data processing logic.

  Replicates the worker's internal mapping and upsert logic using fixture
  data, then asserts the resulting database state.
  """

  # -- helpers that mirror PeopleWorker internals --

  defp map_person(item) do
    mal_id = item["mal_id"]
    name = item["name"]

    if is_nil(mal_id) or is_nil(name) do
      nil
    else
      %{
        mal_id: mal_id,
        name: name,
        given_name: item["given_name"],
        family_name: item["family_name"],
        alternate_names: item["alternate_names"] || [],
        birthday: parse_date(item["birthday"]),
        website_url: item["website_url"],
        image_url: get_in(item, ["images", "jpg", "image_url"]),
        about: item["about"],
        favorites_count: item["favorites"] || 0
      }
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
      |> Enum.map(&map_person/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn entry -> Map.merge(entry, %{inserted_at: now, updated_at: now}) end)

    entries
    |> Enum.chunk_every(50)
    |> Enum.each(fn batch ->
      Repo.insert_all("people", batch,
        on_conflict:
          {:replace,
           [
             :name,
             :given_name,
             :family_name,
             :alternate_names,
             :birthday,
             :website_url,
             :image_url,
             :about,
             :favorites_count,
             :updated_at
           ]},
        conflict_target: :mal_id
      )
    end)

    entries
  end

  # -- tests --

  describe "map_person/1" do
    test "maps all fields from API data" do
      item = List.first(JikanFixtures.people_page_response()["data"])
      person = map_person(item)

      assert person.mal_id == 1
      assert person.name == "Seki, Tomokazu"
      assert person.given_name == "智一"
      assert person.family_name == "関"
      assert person.alternate_names == ["Seki Mondoya", "門戸 開"]
      assert person.birthday == ~D[1972-09-08]
      assert person.website_url == nil
      assert person.image_url == "https://cdn.myanimelist.net/images/voiceactors/1/85360.jpg"
      assert person.about == "Hometown: Tokyo"
      assert person.favorites_count == 6243
    end

    test "extracts image_url from nested images.jpg.image_url" do
      item = List.first(JikanFixtures.people_page_response()["data"])
      person = map_person(item)

      assert person.image_url == "https://cdn.myanimelist.net/images/voiceactors/1/85360.jpg"
    end

    test "parses birthday to Date" do
      item = List.first(JikanFixtures.people_page_response()["data"])
      person = map_person(item)

      assert %Date{} = person.birthday
      assert person.birthday == ~D[1972-09-08]
    end

    test "handles nil birthday" do
      items = JikanFixtures.people_multi_response()["data"]
      item = Enum.at(items, 2)
      person = map_person(item)

      assert person.birthday == nil
    end

    test "defaults alternate_names to empty list when nil" do
      items = JikanFixtures.people_multi_response()["data"]
      item = Enum.at(items, 2)
      person = map_person(item)

      assert person.alternate_names == []
    end

    test "defaults favorites_count to 0 when nil" do
      items = JikanFixtures.people_multi_response()["data"]
      item = Enum.at(items, 2)
      person = map_person(item)

      assert person.favorites_count == 0
    end

    test "maps favorites field to favorites_count" do
      items = JikanFixtures.people_multi_response()["data"]
      item = Enum.at(items, 1)
      person = map_person(item)

      assert person.favorites_count == 15_000
    end

    test "returns nil for item with missing mal_id" do
      item = %{
        "mal_id" => nil,
        "name" => "Test Person",
        "given_name" => nil,
        "family_name" => nil,
        "alternate_names" => [],
        "birthday" => nil,
        "website_url" => nil,
        "images" => %{"jpg" => %{"image_url" => nil}},
        "about" => nil,
        "favorites" => 0
      }

      assert map_person(item) == nil
    end

    test "returns nil for item with missing name" do
      item = %{
        "mal_id" => 99,
        "name" => nil,
        "given_name" => nil,
        "family_name" => nil,
        "alternate_names" => [],
        "birthday" => nil,
        "website_url" => nil,
        "images" => %{"jpg" => %{"image_url" => nil}},
        "about" => nil,
        "favorites" => 0
      }

      assert map_person(item) == nil
    end
  end

  describe "people upsert into database" do
    test "inserts people into the people table" do
      items = JikanFixtures.people_multi_response()["data"]
      process_and_upsert(items)

      rows =
        Repo.all(
          from(p in "people",
            select: %{
              mal_id: p.mal_id,
              name: p.name,
              given_name: p.given_name,
              family_name: p.family_name,
              birthday: p.birthday,
              favorites_count: p.favorites_count
            },
            order_by: p.mal_id
          )
        )

      assert length(rows) == 3

      first = Enum.at(rows, 0)
      assert first.mal_id == 1
      assert first.name == "Seki, Tomokazu"
      assert first.given_name == "智一"
      assert first.family_name == "関"
      assert first.birthday == ~D[1972-09-08]
      assert first.favorites_count == 6243

      second = Enum.at(rows, 1)
      assert second.mal_id == 2
      assert second.name == "Hanazawa, Kana"
      assert second.favorites_count == 15_000

      third = Enum.at(rows, 2)
      assert third.mal_id == 3
      assert third.name == "Unknown Person"
      assert third.birthday == nil
      assert third.favorites_count == 0
    end

    test "stores alternate_names as array" do
      items = JikanFixtures.people_page_response()["data"]
      process_and_upsert(items)

      row =
        Repo.one(
          from(p in "people",
            where: p.mal_id == 1,
            select: %{alternate_names: p.alternate_names}
          )
        )

      assert row.alternate_names == ["Seki Mondoya", "門戸 開"]
    end

    test "stores website_url when present" do
      items = JikanFixtures.people_multi_response()["data"]
      process_and_upsert(items)

      row =
        Repo.one(
          from(p in "people",
            where: p.mal_id == 2,
            select: %{website_url: p.website_url}
          )
        )

      assert row.website_url == "https://www.hanazawakana.com"
    end

    test "upsert updates existing person on conflict" do
      items = JikanFixtures.people_page_response()["data"]
      process_and_upsert(items)

      row =
        Repo.one(
          from(p in "people",
            where: p.mal_id == 1,
            select: %{favorites_count: p.favorites_count}
          )
        )

      assert row.favorites_count == 6243

      # Update favorites and re-upsert
      updated_items = [
        %{
          "mal_id" => 1,
          "name" => "Seki, Tomokazu",
          "given_name" => "智一",
          "family_name" => "関",
          "alternate_names" => ["Seki Mondoya", "門戸 開"],
          "birthday" => "1972-09-08T00:00:00+00:00",
          "website_url" => nil,
          "images" => %{
            "jpg" => %{
              "image_url" => "https://cdn.myanimelist.net/images/voiceactors/1/85360.jpg"
            }
          },
          "about" => "Hometown: Tokyo",
          "favorites" => 9999
        }
      ]

      process_and_upsert(updated_items)

      updated_row =
        Repo.one(
          from(p in "people",
            where: p.mal_id == 1,
            select: %{favorites_count: p.favorites_count}
          )
        )

      assert updated_row.favorites_count == 9999
    end

    test "upsert does not duplicate rows" do
      items = JikanFixtures.people_page_response()["data"]
      process_and_upsert(items)
      process_and_upsert(items)

      count = Repo.one(from(p in "people", select: count(p.id)))
      assert count == 1
    end
  end
end
