defmodule Mix.Tasks.AnilistSync do
  @moduledoc """
  Sync data from AniList to the database.

  ## Usage

      # Show stats (no sync)
      mix anilist_sync stats

      # Quick test (tags + 2 pages anime + 2 pages manga)
      mix anilist_sync test

      # Sync tags only
      mix anilist_sync tags

      # Sync anime (all or range)
      mix anilist_sync anime
      mix anilist_sync anime 1 10    # pages 1-10

      # Sync manga (all or range)
      mix anilist_sync manga
      mix anilist_sync manga 1 10    # pages 1-10

      # Full sync (everything)
      mix anilist_sync full
  """

  use Mix.Task

  require Logger

  alias Yunaos.Anilist.Orchestrator

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    case args do
      ["stats"] ->
        Orchestrator.stats()

      ["test"] ->
        run_with_result(fn -> Orchestrator.quick_test() end)

      ["tags"] ->
        run_with_result(fn -> Orchestrator.sync_tags() end)

      ["anime"] ->
        run_with_result(fn -> Orchestrator.sync_anime() end)

      ["anime", start_page, end_page] ->
        opts = [start_page: String.to_integer(start_page), end_page: String.to_integer(end_page)]
        run_with_result(fn -> Orchestrator.sync_anime(opts) end)

      ["manga"] ->
        run_with_result(fn -> Orchestrator.sync_manga() end)

      ["manga", start_page, end_page] ->
        opts = [start_page: String.to_integer(start_page), end_page: String.to_integer(end_page)]
        run_with_result(fn -> Orchestrator.sync_manga(opts) end)

      ["full"] ->
        run_with_result(fn -> Orchestrator.full_sync() end)

      ["page", "anime", page] ->
        run_with_result(fn -> Orchestrator.test_anime_page(String.to_integer(page)) end)

      ["page", "manga", page] ->
        run_with_result(fn -> Orchestrator.test_manga_page(String.to_integer(page)) end)

      _ ->
        IO.puts("""
        Usage:
          mix anilist_sync stats              # Show sync statistics
          mix anilist_sync test               # Quick test (tags + 2 pages each)
          mix anilist_sync tags             # Sync tags only
          mix anilist_sync anime              # Sync all anime
          mix anilist_sync anime 1 10         # Sync anime pages 1-10
          mix anilist_sync manga              # Sync all manga
          mix anilist_sync manga 1 10         # Sync manga pages 1-10
          mix anilist_sync full               # Full sync (tags + anime + manga)
          mix anilist_sync page anime 1       # Test single anime page
          mix anilist_sync page manga 1       # Test single manga page
        """)
    end
  end

  defp run_with_result(fun) do
    case fun.() do
      {:ok, result} ->
        IO.puts("\n✓ Success!")
        IO.inspect(result, label: "Result", pretty: true)

      {:error, reason} ->
        IO.puts("\n✗ Failed!")
        IO.inspect(reason, label: "Error", pretty: true)

      {:error, reason, page} ->
        IO.puts("\n✗ Failed at page #{page}!")
        IO.inspect(reason, label: "Error", pretty: true)
    end
  end
end
