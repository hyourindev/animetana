defmodule Yunaos.Jikan.Workers.RecommendationsWorker do
  @moduledoc """
  Phase 6 worker (STUB): Would paginate `GET /recommendations/anime` and
  `GET /recommendations/manga` to collect MAL user recommendations.

  Skipped because our schema does not have a recommendations table.
  """

  require Logger

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Skipped - no recommendations table in our schema."
  def run do
    Logger.info(
      "[RecommendationsWorker] Phase 6 recommendations - skipped " <>
        "(no recommendations table in our schema)"
    )

    :ok
  end
end
