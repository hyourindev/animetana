defmodule Yunaos.Anilist.Orchestrator do
  @moduledoc """
  Orchestrates the AniList data collection process.

  ## Usage

      # Full sync (genres + all anime + all manga)
      Orchestrator.full_sync()

      # Sync genres only
      Orchestrator.sync_genres()

      # Sync anime only (optionally with page range)
      Orchestrator.sync_anime()
      Orchestrator.sync_anime(start_page: 1, end_page: 10)

      # Sync manga only
      Orchestrator.sync_manga()
      Orchestrator.sync_manga(start_page: 1, end_page: 10)

      # Test with single page
      Orchestrator.test_anime_page(1)
      Orchestrator.test_manga_page(1)

  ## API Call Estimates

  - Genres: 1 call (~417 tags)
  - Anime: ~400 calls (~20,000 items at 50/page)
  - Manga: ~2,000 calls (~100,000 items at 50/page)

  At 86 req/min, full sync takes:
  - Anime: ~58 minutes
  - Manga: ~58 minutes
  - Total: ~2 hours
  """

  require Logger

  alias Yunaos.Anilist.Workers.{TagsWorker, CatalogWorker}

  # ===========================================================================
  # FULL SYNC
  # ===========================================================================

  @doc """
  Runs a full sync: tags, then anime, then manga.
  """
  def full_sync(opts \\ []) do
    Logger.info("=" |> String.duplicate(60))
    Logger.info("[Orchestrator] Starting FULL SYNC")
    Logger.info("=" |> String.duplicate(60))

    start_time = System.monotonic_time(:second)

    with {:ok, tag_count} <- sync_tags(),
         {:ok, anime_count} <- sync_anime(opts),
         {:ok, manga_count} <- sync_manga(opts) do
      elapsed = System.monotonic_time(:second) - start_time

      Logger.info("=" |> String.duplicate(60))
      Logger.info("[Orchestrator] FULL SYNC COMPLETED in #{elapsed}s")
      Logger.info("  Tags: #{tag_count}")
      Logger.info("  Anime: #{anime_count}")
      Logger.info("  Manga: #{manga_count}")
      Logger.info("=" |> String.duplicate(60))

      {:ok, %{tags: tag_count, anime: anime_count, manga: manga_count, elapsed_seconds: elapsed}}
    else
      {:error, reason} = err ->
        Logger.error("[Orchestrator] FULL SYNC FAILED: #{inspect(reason)}")
        err

      {:error, reason, page} ->
        Logger.error("[Orchestrator] FULL SYNC FAILED at page #{page}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ===========================================================================
  # INDIVIDUAL SYNCS
  # ===========================================================================

  @doc """
  Syncs all AniList tags.
  """
  def sync_tags do
    Logger.info("[Orchestrator] Syncing tags...")
    TagsWorker.run()
  end

  @doc """
  Syncs anime catalog.

  ## Options
    - `:start_page` - Page to start from (default: 1)
    - `:end_page` - Page to stop at (default: nil = all)
  """
  def sync_anime(opts \\ []) do
    Logger.info("[Orchestrator] Syncing anime...")

    on_page = fn page, count ->
      if rem(page, 10) == 0 do
        Logger.info("[Orchestrator] Anime progress: page #{page}, #{count} items")
      end
    end

    CatalogWorker.run(:anime, Keyword.put(opts, :on_page, on_page))
  end

  @doc """
  Syncs manga catalog.

  ## Options
    - `:start_page` - Page to start from (default: 1)
    - `:end_page` - Page to stop at (default: nil = all)
  """
  def sync_manga(opts \\ []) do
    Logger.info("[Orchestrator] Syncing manga...")

    on_page = fn page, count ->
      if rem(page, 10) == 0 do
        Logger.info("[Orchestrator] Manga progress: page #{page}, #{count} items")
      end
    end

    CatalogWorker.run(:manga, Keyword.put(opts, :on_page, on_page))
  end

  # ===========================================================================
  # TESTING / DEBUGGING
  # ===========================================================================

  @doc """
  Fetches and processes a single anime page. Useful for testing.
  """
  def test_anime_page(page \\ 1) do
    Logger.info("[Orchestrator] Testing anime page #{page}...")
    CatalogWorker.fetch_single_page(:anime, page)
  end

  @doc """
  Fetches and processes a single manga page. Useful for testing.
  """
  def test_manga_page(page \\ 1) do
    Logger.info("[Orchestrator] Testing manga page #{page}...")
    CatalogWorker.fetch_single_page(:manga, page)
  end

  @doc """
  Quick test: syncs tags + first 2 pages of anime + first 2 pages of manga.
  """
  def quick_test do
    Logger.info("[Orchestrator] Running quick test...")

    with {:ok, tags} <- sync_tags(),
         {:ok, anime} <- sync_anime(start_page: 1, end_page: 2),
         {:ok, manga} <- sync_manga(start_page: 1, end_page: 2) do
      {:ok, %{tags: tags, anime: anime, manga: manga}}
    end
  end

  @doc """
  Shows sync statistics without actually syncing.
  """
  def stats do
    anime_query = """
    query { Page(page: 1, perPage: 1) { pageInfo { total lastPage } media(type: ANIME, sort: ID) { id } } }
    """

    manga_query = """
    query { Page(page: 1, perPage: 1) { pageInfo { total lastPage } media(type: MANGA, sort: ID) { id } } }
    """

    tags_query = """
    query { MediaTagCollection { id } }
    """

    IO.puts("\n=== AniList Sync Statistics ===\n")

    # Tags
    case do_query(tags_query) do
      {:ok, %{"MediaTagCollection" => tags}} ->
        IO.puts("Tags: #{length(tags)}")
        IO.puts("  API calls needed: 1")

      _ ->
        IO.puts("Genres: (failed to fetch)")
    end

    # Anime
    case do_query(anime_query) do
      {:ok, %{"Page" => %{"pageInfo" => info}}} ->
        IO.puts("\nAnime: #{info["total"]} total")
        IO.puts("  Pages: #{info["lastPage"]}")
        IO.puts("  API calls needed: #{info["lastPage"]}")
        IO.puts("  Est. time at 86 req/min: #{Float.round(info["lastPage"] / 86, 1)} minutes")

      _ ->
        IO.puts("Anime: (failed to fetch)")
    end

    # Manga
    case do_query(manga_query) do
      {:ok, %{"Page" => %{"pageInfo" => info}}} ->
        IO.puts("\nManga: #{info["total"]} total")
        IO.puts("  Pages: #{info["lastPage"]}")
        IO.puts("  API calls needed: #{info["lastPage"]}")
        IO.puts("  Est. time at 86 req/min: #{Float.round(info["lastPage"] / 86, 1)} minutes")

      _ ->
        IO.puts("Manga: (failed to fetch)")
    end

    IO.puts("")
    :ok
  end

  defp do_query(query) do
    body = Jason.encode!(%{"query" => query})

    case Req.post("https://graphql.anilist.co",
           body: body,
           headers: [{"content-type", "application/json"}],
           receive_timeout: 30_000
         ) do
      {:ok, %{status: 200, body: %{"data" => data}}} -> {:ok, data}
      _ -> {:error, :failed}
    end
  end
end
