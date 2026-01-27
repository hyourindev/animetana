defmodule Yunaos.Jikan.Workers.NewsWorker do
  @moduledoc """
  Phase 6 worker (STUB): Would fetch news articles from the Jikan API.

  Skipped because our schema does not have a news table.
  """

  require Logger

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Skipped - no news table in our schema."
  def run do
    Logger.info(
      "[NewsWorker] Phase 6 news - skipped (no news table in our schema)"
    )

    :ok
  end
end
