defmodule Yunaos.Jikan.Workers.MangaRelationsWorker do
  @moduledoc """
  Phase 4 worker (STUB): Manga relations (sequels, prequels, adaptations)
  are already handled inside `MangaFullWorker` which processes the
  `/manga/{id}/full` response including the `relations` field.
  """

  require Logger

  @doc "Entry point. Skipped - handled by MangaFullWorker."
  def run do
    Logger.info(
      "[MangaRelationsWorker] Skipped - relations are populated by MangaFullWorker"
    )

    :ok
  end
end
