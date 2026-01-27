defmodule Yunaos.Jikan.Workers.CharacterVoicesWorker do
  @moduledoc """
  Phase 5 worker (STUB): Would fetch `GET /characters/{mal_id}/voices` for
  each character to get voice actor data.

  This endpoint provides character -> voice actor -> language mappings WITHOUT
  anime context. Since the `character_voice_actors` table requires `anime_id`,
  and the `anime_characters_worker` already populates this data with proper
  anime context, this worker is intentionally skipped.
  """

  require Logger

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Skipped - covered by anime_characters_worker."
  def run do
    Logger.info(
      "[CharacterVoicesWorker] Skipped - character voice actor data is covered " <>
        "by anime_characters_worker which provides proper anime context for the " <>
        "character_voice_actors table"
    )

    :ok
  end
end
