defmodule Animetana.Anilist.Client do
  @moduledoc """
  GraphQL client for the AniList API with batch query support.

  AniList allows fetching up to 50 items per request via GraphQL,
  making it much faster than REST APIs for bulk data collection.

  Rate limits:
  - Normal: 90 req/min (~1.5 req/s)
  - Degraded: 30 req/min (~0.5 req/s)
  """

  require Logger

  @base_url "https://graphql.anilist.co"
  @rate_limit_ms 2_000  # 30 req/min = 2s between requests (safe for degraded mode)
  @batch_size 50
  @request_timeout 30_000

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Fetches anime by MAL IDs in batches.
  Returns a map of mal_id => anime_data for successful fetches.
  """
  def fetch_anime_batch(mal_ids) when is_list(mal_ids) do
    query = """
    query ($ids: [Int]) {
      Page(perPage: 50) {
        media(idMal_in: $ids, type: ANIME) {
          id
          idMal
          title {
            romaji
            english
            native
          }
          description
          episodes
          duration
          status
          season
          seasonYear
          format
          source
          genres
          tags {
            name
            rank
            isMediaSpoiler
          }
          studios {
            nodes {
              id
              name
              isAnimationStudio
            }
          }
          staff {
            edges {
              role
              node {
                id
                name {
                  full
                  native
                }
              }
            }
          }
          characters {
            edges {
              role
              voiceActors(language: JAPANESE) {
                id
                name {
                  full
                  native
                }
                language
              }
              node {
                id
                name {
                  full
                  native
                }
              }
            }
          }
          relations {
            edges {
              relationType
              node {
                id
                idMal
                type
                title {
                  romaji
                }
              }
            }
          }
          externalLinks {
            site
            url
          }
          averageScore
          meanScore
          popularity
          favourites
          startDate {
            year
            month
            day
          }
          endDate {
            year
            month
            day
          }
          coverImage {
            large
            medium
          }
          bannerImage
          trailer {
            id
            site
          }
        }
      }
    }
    """

    do_batch_query(query, mal_ids, :idMal)
  end

  @doc """
  Fetches manga by MAL IDs in batches.
  """
  def fetch_manga_batch(mal_ids) when is_list(mal_ids) do
    query = """
    query ($ids: [Int]) {
      Page(perPage: 50) {
        media(idMal_in: $ids, type: MANGA) {
          id
          idMal
          title {
            romaji
            english
            native
          }
          description
          chapters
          volumes
          status
          format
          source
          genres
          tags {
            name
            rank
            isMediaSpoiler
          }
          staff {
            edges {
              role
              node {
                id
                name {
                  full
                  native
                }
              }
            }
          }
          characters {
            edges {
              role
              node {
                id
                name {
                  full
                  native
                }
              }
            }
          }
          relations {
            edges {
              relationType
              node {
                id
                idMal
                type
                title {
                  romaji
                }
              }
            }
          }
          averageScore
          meanScore
          popularity
          favourites
          startDate {
            year
            month
            day
          }
          endDate {
            year
            month
            day
          }
          coverImage {
            large
            medium
          }
        }
      }
    }
    """

    do_batch_query(query, mal_ids, :idMal)
  end

  @doc """
  Fetches characters by AniList IDs in batches.
  Note: AniList doesn't support querying characters by MAL ID directly,
  so we need to map them first or use AniList IDs.
  """
  def fetch_characters_batch(anilist_ids) when is_list(anilist_ids) do
    query = """
    query ($ids: [Int]) {
      Page(perPage: 50) {
        characters(id_in: $ids) {
          id
          name {
            full
            native
            alternative
          }
          description
          gender
          dateOfBirth {
            year
            month
            day
          }
          age
          bloodType
          image {
            large
            medium
          }
          favourites
          media {
            edges {
              characterRole
              voiceActors {
                id
                name {
                  full
                  native
                }
                language
              }
              node {
                id
                idMal
                type
                title {
                  romaji
                }
              }
            }
          }
        }
      }
    }
    """

    do_batch_query(query, anilist_ids, :id)
  end

  @doc """
  Fetches staff/voice actors by AniList IDs in batches.
  """
  def fetch_staff_batch(anilist_ids) when is_list(anilist_ids) do
    query = """
    query ($ids: [Int]) {
      Page(perPage: 50) {
        staff(id_in: $ids) {
          id
          name {
            full
            native
            alternative
          }
          language
          description
          primaryOccupations
          gender
          dateOfBirth {
            year
            month
            day
          }
          dateOfDeath {
            year
            month
            day
          }
          age
          yearsActive
          homeTown
          bloodType
          image {
            large
            medium
          }
          favourites
          characters {
            edges {
              role
              media {
                id
                idMal
                type
                title {
                  romaji
                }
              }
              node {
                id
                name {
                  full
                }
              }
            }
          }
          staffMedia {
            edges {
              staffRole
              node {
                id
                idMal
                type
                title {
                  romaji
                }
              }
            }
          }
        }
      }
    }
    """

    do_batch_query(query, anilist_ids, :id)
  end

  @doc """
  Fetches all anime with voice actors in batches, paginating through the entire database.
  Calls the callback with each batch of results.
  """
  def stream_all_anime(callback) do
    stream_paginated_query(:ANIME, callback)
  end

  @doc """
  Fetches all manga in batches, paginating through the entire database.
  """
  def stream_all_manga(callback) do
    stream_paginated_query(:MANGA, callback)
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp do_batch_query(query, ids, id_field) do
    ids
    |> Enum.chunk_every(@batch_size)
    |> Enum.reduce(%{}, fn batch, acc ->
      Process.sleep(@rate_limit_ms)

      case execute_query(query, %{"ids" => batch}) do
        {:ok, data} ->
          results = extract_results(data, id_field)
          Map.merge(acc, results)

        {:error, reason} ->
          Logger.error("[AniList] Batch query failed: #{inspect(reason)}")
          acc
      end
    end)
  end

  defp stream_paginated_query(media_type, callback) do
    query = """
    query ($page: Int, $perPage: Int, $type: MediaType) {
      Page(page: $page, perPage: $perPage) {
        pageInfo {
          hasNextPage
          currentPage
          lastPage
          total
        }
        media(type: $type, sort: ID) {
          id
          idMal
          title {
            romaji
            english
            native
          }
          description
          episodes
          chapters
          volumes
          duration
          status
          season
          seasonYear
          format
          source
          genres
          tags {
            name
            rank
            isMediaSpoiler
          }
          studios {
            nodes {
              id
              name
              isAnimationStudio
            }
          }
          staff(perPage: 25) {
            edges {
              role
              node {
                id
                name {
                  full
                  native
                }
              }
            }
          }
          characters(perPage: 25) {
            edges {
              role
              voiceActors(language: JAPANESE) {
                id
                name {
                  full
                  native
                }
                language
              }
              node {
                id
                name {
                  full
                  native
                }
              }
            }
          }
          relations {
            edges {
              relationType
              node {
                id
                idMal
                type
              }
            }
          }
          averageScore
          meanScore
          popularity
          favourites
          startDate {
            year
            month
            day
          }
          endDate {
            year
            month
            day
          }
          coverImage {
            large
            medium
          }
        }
      }
    }
    """

    do_stream_pages(query, media_type, 1, callback, 0)
  end

  defp do_stream_pages(query, media_type, page, callback, total_fetched) do
    Process.sleep(@rate_limit_ms)

    variables = %{"page" => page, "perPage" => @batch_size, "type" => media_type}

    case execute_query(query, variables) do
      {:ok, %{"Page" => %{"pageInfo" => page_info, "media" => media}}} ->
        count = length(media)
        new_total = total_fetched + count

        Logger.info("[AniList] Page #{page}/#{page_info["lastPage"]} - fetched #{count} items (total: #{new_total}/#{page_info["total"]})")

        callback.(media, page)

        if page_info["hasNextPage"] do
          do_stream_pages(query, media_type, page + 1, callback, new_total)
        else
          {:ok, new_total}
        end

      {:error, reason} ->
        Logger.error("[AniList] Stream failed at page #{page}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp execute_query(query, variables) do
    body = Jason.encode!(%{"query" => query, "variables" => variables})

    case Req.post(@base_url,
           body: body,
           headers: [{"content-type", "application/json"}],
           receive_timeout: @request_timeout
         ) do
      {:ok, %{status: 200, body: %{"data" => data}}} ->
        {:ok, data}

      {:ok, %{status: 429, headers: headers}} ->
        retry_after = get_retry_after(headers)
        Logger.warning("[AniList] Rate limited. Waiting #{retry_after}s...")
        Process.sleep(retry_after * 1000)
        execute_query(query, variables)

      {:ok, %{status: status, body: body}} ->
        {:error, {status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_results(data, id_field) do
    # Handle different response structures
    items =
      case data do
        %{"Page" => %{"media" => media}} -> media
        %{"Page" => %{"characters" => chars}} -> chars
        %{"Page" => %{"staff" => staff}} -> staff
        _ -> []
      end

    items
    |> Enum.filter(&(&1[Atom.to_string(id_field)] != nil))
    |> Map.new(fn item -> {item[Atom.to_string(id_field)], item} end)
  end

  defp get_retry_after(headers) do
    case Enum.find(headers, fn {k, _} -> String.downcase(k) == "retry-after" end) do
      {_, value} -> String.to_integer(value)
      nil -> 60
    end
  end
end
