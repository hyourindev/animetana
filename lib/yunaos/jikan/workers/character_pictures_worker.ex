defmodule Yunaos.Jikan.Workers.CharacterPicturesWorker do
  @moduledoc """
  Phase 5 worker: For each character, fetches `GET /characters/{mal_id}/pictures`
  and upserts image entries into the `pictures` table with
  `imageable_type` = "character".
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  @rate_limit_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Fetches pictures for every character record."
  def run do
    Logger.info("[CharacterPicturesWorker] Starting character pictures sync")

    character_list = Repo.all(from(c in "characters", select: {c.id, c.mal_id}))
    total = length(character_list)
    Logger.info("[CharacterPicturesWorker] Found #{total} characters to process")

    character_list
    |> Enum.with_index(1)
    |> Enum.each(fn {{character_id, mal_id}, idx} ->
      try do
        Logger.info("[CharacterPicturesWorker] Processing #{idx}/#{total} mal_id=#{mal_id}")
        process_character(character_id, mal_id)
      rescue
        e ->
          Logger.error(
            "[CharacterPicturesWorker] Failed for character mal_id=#{mal_id}: #{inspect(e)}"
          )
      end

      Process.sleep(@rate_limit_ms)
    end)

    Logger.info("[CharacterPicturesWorker] Character pictures sync complete")
  end

  # ---------------------------------------------------------------------------
  # Processing
  # ---------------------------------------------------------------------------

  defp process_character(character_id, mal_id) do
    case Client.get("/characters/#{mal_id}/pictures", []) do
      {:ok, %{"data" => data}} ->
        upsert_pictures(character_id, data)

      {:error, :not_found} ->
        Logger.warning("[CharacterPicturesWorker] Character not found on Jikan: mal_id=#{mal_id}")

      {:error, reason} ->
        Logger.error("[CharacterPicturesWorker] API error for mal_id=#{mal_id}: #{inspect(reason)}")
    end
  end

  defp upsert_pictures(character_id, pictures) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Enum.each(pictures, fn pic ->
      jpg = pic["jpg"] || %{}
      image_url = jpg["large_image_url"] || jpg["image_url"]
      small_image_url = jpg["small_image_url"] || jpg["image_url"]

      if image_url do
        attrs = %{
          imageable_type: "character",
          imageable_id: character_id,
          image_url: image_url,
          small_image_url: small_image_url,
          inserted_at: now,
          updated_at: now
        }

        Repo.insert_all(
          "pictures",
          [attrs],
          on_conflict: :nothing,
          conflict_target: [:imageable_type, :imageable_id, :image_url]
        )
      end
    end)
  end
end
