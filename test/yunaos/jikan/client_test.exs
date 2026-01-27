defmodule Yunaos.Jikan.ClientTest do
  use ExUnit.Case, async: false

  alias Yunaos.Jikan.Client

  # All tests in this module hit the real Jikan API.
  # Exclude from CI with: mix test --exclude external
  @moduletag :external

  # Jikan enforces 3 req/sec burst, 60 req/min sustained.
  # We add a small delay between tests to avoid rate limiting.
  setup do
    Process.sleep(1_200)
    :ok
  end

  # ---------------------------------------------------------------------------
  # get/2
  # ---------------------------------------------------------------------------

  describe "get/2" do
    test "returns {:ok, body} with a map for a valid resource" do
      assert {:ok, body} = Client.get("/genres/anime")
      assert is_map(body)
      assert Map.has_key?(body, "data")

      data = body["data"]
      assert is_list(data)
      assert length(data) > 0

      first = hd(data)
      assert Map.has_key?(first, "mal_id")
      assert Map.has_key?(first, "name")
      assert is_integer(first["mal_id"])
      assert is_binary(first["name"])
    end

    test "returns {:error, :not_found} for a non-existent resource" do
      assert {:error, :not_found} = Client.get("/anime/99999999")
    end

    test "accepts query parameters" do
      assert {:ok, body} = Client.get("/anime", q: "Naruto", limit: 1)
      assert is_map(body)
      assert Map.has_key?(body, "data")

      data = body["data"]
      assert is_list(data)
      assert length(data) == 1
    end

    test "returns body with pagination info for paginated endpoints" do
      assert {:ok, body} = Client.get("/anime", limit: 1, page: 1)

      assert Map.has_key?(body, "pagination")
      pagination = body["pagination"]
      assert Map.has_key?(pagination, "has_next_page")
      assert Map.has_key?(pagination, "last_visible_page")
      assert is_boolean(pagination["has_next_page"])
    end

    test "returns a map body for a single-resource endpoint" do
      # Anime ID 1 is Cowboy Bebop, a well-known stable entry
      assert {:ok, body} = Client.get("/anime/1")
      assert is_map(body)
      assert Map.has_key?(body, "data")

      data = body["data"]
      assert is_map(data)
      assert data["mal_id"] == 1
      assert is_binary(data["title"])
    end
  end

  # ---------------------------------------------------------------------------
  # get_paginated/2
  # ---------------------------------------------------------------------------

  describe "get_paginated/2" do
    test "collects all pages into a single list" do
      # Genres is a small, non-paginated endpoint -- returns all data in one page.
      assert {:ok, all_data} = Client.get_paginated("/genres/anime")
      assert is_list(all_data)
      assert length(all_data) > 0

      # Every item should have the expected genre shape
      Enum.each(all_data, fn genre ->
        assert Map.has_key?(genre, "mal_id")
        assert Map.has_key?(genre, "name")
      end)
    end

    test "returns {:error, :not_found} for invalid paginated resource" do
      assert {:error, :not_found} = Client.get_paginated("/anime/99999999")
    end
  end

  # ---------------------------------------------------------------------------
  # get_all_pages/3
  # ---------------------------------------------------------------------------

  describe "get_all_pages/3" do
    test "invokes the callback for each page and collects results" do
      {:ok, results} =
        Client.get_all_pages("/genres/anime", [], fn page_data, page_number ->
          assert is_list(page_data)
          assert is_integer(page_number)
          assert page_number >= 1
          length(page_data)
        end)

      assert is_list(results)
      assert length(results) >= 1
      # The callback returned lengths, so each result should be a positive integer
      Enum.each(results, fn count ->
        assert is_integer(count)
        assert count > 0
      end)
    end
  end

  # ---------------------------------------------------------------------------
  # Response shape validation
  # ---------------------------------------------------------------------------

  describe "response shape for anime endpoint" do
    test "anime search response has expected structure" do
      assert {:ok, body} = Client.get("/anime", q: "Naruto", limit: 1)

      [anime | _] = body["data"]

      # Fields expected by workers
      assert Map.has_key?(anime, "mal_id")
      assert Map.has_key?(anime, "title")
      assert Map.has_key?(anime, "type")
      assert Map.has_key?(anime, "status")
      assert Map.has_key?(anime, "images")

      images = anime["images"]
      assert Map.has_key?(images, "jpg")
      assert Map.has_key?(images["jpg"], "image_url")
    end
  end

  describe "response shape for genres endpoint" do
    test "genres response items have expected fields" do
      assert {:ok, body} = Client.get("/genres/anime")
      first = hd(body["data"])

      assert Map.has_key?(first, "mal_id")
      assert Map.has_key?(first, "name")
      assert Map.has_key?(first, "count")
      assert is_integer(first["mal_id"])
      assert is_binary(first["name"])
      assert is_integer(first["count"])
    end
  end
end
