defmodule Yunaos.Jikan.Workers.AnimeRelationsWorker do
  @moduledoc """
  Phase 3 worker (STUB): Anime relations (sequels, prequels, adaptations)
  are already handled inside `AnimeFullWorker` which processes the
  `/anime/{id}/full` response including the `relations` field.
  """

  require Logger

  @doc "Entry point. Skipped - handled by AnimeFullWorker."
  def run do
    Logger.info(
      "[AnimeRelationsWorker] Skipped - relations are populated by AnimeFullWorker"
    )

    :ok
  end
end
