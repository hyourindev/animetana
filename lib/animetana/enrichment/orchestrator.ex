defmodule Animetana.Enrichment.Orchestrator do
  @moduledoc """
  Orchestrates AI enrichment for anime, manga, and characters.

  ## Usage

      Orchestrator.enrich_anime(limit: 100)
      Orchestrator.enrich_manga(limit: 100)
      Orchestrator.enrich_characters(limit: 100)
      Orchestrator.stats()
  """

  require Logger

  alias Animetana.Enrichment.{AnimeEnricher, MangaEnricher, CharacterEnricher}
  alias Animetana.Repo

  import Ecto.Query

  def enrich_anime(opts \\ []), do: AnimeEnricher.run(opts)
  def enrich_manga(opts \\ []), do: MangaEnricher.run(opts)
  def enrich_characters(opts \\ []), do: CharacterEnricher.run(opts)

  @doc """
  Full enrichment: anime, manga, then characters.
  """
  def full_enrich(opts \\ []) do
    Logger.info("=" |> String.duplicate(60))
    Logger.info("[Orchestrator] Starting FULL ENRICHMENT")
    Logger.info("=" |> String.duplicate(60))

    start_time = System.monotonic_time(:second)

    with {:ok, anime} <- enrich_anime(opts),
         {:ok, manga} <- enrich_manga(opts),
         {:ok, chars} <- enrich_characters(opts) do
      elapsed = System.monotonic_time(:second) - start_time

      result = %{anime: anime, manga: manga, characters: chars, elapsed_seconds: elapsed}

      Logger.info("=" |> String.duplicate(60))
      Logger.info("[Orchestrator] COMPLETE in #{elapsed}s: #{inspect(result)}")
      Logger.info("=" |> String.duplicate(60))

      {:ok, result}
    end
  end

  @doc """
  Shows enrichment statistics.
  """
  def stats do
    IO.puts("\n=== AI Enrichment Statistics ===\n")

    # Anime
    anime_total = count_total("anime")
    anime_done = count_enriched("anime")
    anime_errors = count_errors("anime")

    IO.puts("Anime:")
    IO.puts("  Total: #{anime_total}")
    IO.puts("  Enriched: #{anime_done}/#{anime_total} (#{pct(anime_done, anime_total)})")
    IO.puts("  Errors: #{anime_errors}")

    # Manga
    manga_total = count_total("manga")
    manga_done = count_enriched("manga")
    manga_errors = count_errors("manga")

    IO.puts("\nManga:")
    IO.puts("  Total: #{manga_total}")
    IO.puts("  Enriched: #{manga_done}/#{manga_total} (#{pct(manga_done, manga_total)})")
    IO.puts("  Errors: #{manga_errors}")

    # Characters
    char_total = count_total("characters")
    char_done = count_enriched("characters")
    char_errors = count_errors("characters")

    IO.puts("\nCharacters:")
    IO.puts("  Total: #{char_total}")
    IO.puts("  Enriched: #{char_done}/#{char_total} (#{pct(char_done, char_total)})")
    IO.puts("  Errors: #{char_errors}")

    IO.puts("")
    :ok
  end

  defp count_total(table) do
    from(t in table, prefix: "contents", where: is_nil(t.deleted_at))
    |> Repo.aggregate(:count)
  end

  defp count_enriched(table) do
    from(t in table,
      prefix: "contents",
      where: is_nil(t.deleted_at) and fragment("COALESCE(?, 0) = 7", t.enrichment_status)
    )
    |> Repo.aggregate(:count)
  end

  defp count_errors(table) do
    from(t in table,
      prefix: "contents",
      where: is_nil(t.deleted_at) and not is_nil(t.enrichment_error)
    )
    |> Repo.aggregate(:count)
  end

  defp pct(part, total) when total > 0, do: "#{Float.round(part / total * 100, 1)}%"
  defp pct(_, _), do: "0%"
end
