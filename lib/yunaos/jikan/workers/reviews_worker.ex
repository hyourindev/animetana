defmodule Yunaos.Jikan.Workers.ReviewsWorker do
  @moduledoc """
  Phase 6 worker (STUB): Would paginate `GET /reviews/anime` and
  `GET /reviews/manga` to collect MAL user reviews.

  Skipped because the `reviews` table in our schema is for platform user
  reviews, not MAL reviews. There is no separate MAL reviews table.
  """

  require Logger

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Skipped - MAL reviews are not stored in our schema."
  def run do
    Logger.info(
      "[ReviewsWorker] Phase 6 reviews - skipped (MAL reviews not stored, " <>
        "our reviews table is for platform users)"
    )

    :ok
  end
end
