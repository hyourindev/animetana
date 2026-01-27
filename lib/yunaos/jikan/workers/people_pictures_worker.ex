defmodule Yunaos.Jikan.Workers.PeoplePicturesWorker do
  @moduledoc """
  Phase 5 worker: For each person, fetches `GET /people/{mal_id}/pictures`
  and upserts image entries into the `pictures` table with
  `imageable_type` = "person".
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  @rate_limit_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Fetches pictures for every person record."
  def run do
    Logger.info("[PeoplePicturesWorker] Starting people pictures sync")

    people_list = Repo.all(from(p in "people", select: {p.id, p.mal_id}))
    total = length(people_list)
    Logger.info("[PeoplePicturesWorker] Found #{total} people to process")

    people_list
    |> Enum.with_index(1)
    |> Enum.each(fn {{person_id, mal_id}, idx} ->
      try do
        Logger.info("[PeoplePicturesWorker] Processing #{idx}/#{total} mal_id=#{mal_id}")
        process_person(person_id, mal_id)
      rescue
        e ->
          Logger.error(
            "[PeoplePicturesWorker] Failed for person mal_id=#{mal_id}: #{inspect(e)}"
          )
      end

      Process.sleep(@rate_limit_ms)
    end)

    Logger.info("[PeoplePicturesWorker] People pictures sync complete")
  end

  # ---------------------------------------------------------------------------
  # Processing
  # ---------------------------------------------------------------------------

  defp process_person(person_id, mal_id) do
    case Client.get("/people/#{mal_id}/pictures", []) do
      {:ok, %{"data" => data}} ->
        upsert_pictures(person_id, data)

      {:error, :not_found} ->
        Logger.warning("[PeoplePicturesWorker] Person not found on Jikan: mal_id=#{mal_id}")

      {:error, reason} ->
        Logger.error("[PeoplePicturesWorker] API error for mal_id=#{mal_id}: #{inspect(reason)}")
    end
  end

  defp upsert_pictures(person_id, pictures) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Enum.each(pictures, fn pic ->
      jpg = pic["jpg"] || %{}
      image_url = jpg["large_image_url"] || jpg["image_url"]
      small_image_url = jpg["small_image_url"] || jpg["image_url"]

      if image_url do
        attrs = %{
          imageable_type: "person",
          imageable_id: person_id,
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
