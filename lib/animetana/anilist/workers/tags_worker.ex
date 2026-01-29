defmodule Animetana.Anilist.Workers.TagsWorker do
  @moduledoc """
  Seeds all AniList tags in our database.

  AniList has ~417 tags.
  This is a one-time seed operation (1 API call).
  """

  require Logger

  alias Animetana.Anilist.Transformer
  alias Animetana.Repo

  @base_url "https://graphql.anilist.co"

  @doc """
  Fetches all AniList tags and inserts them.
  Returns {:ok, count} or {:error, reason}.
  """
  def run do
    Logger.info("[TagsWorker] Starting tag seed from AniList...")

    with {:ok, tags} <- fetch_all_tags(),
         {:ok, count} <- insert_tags(tags) do
      Logger.info("[TagsWorker] Completed! Inserted #{count} tags")
      {:ok, count}
    else
      {:error, reason} = err ->
        Logger.error("[TagsWorker] Failed: #{inspect(reason)}")
        err
    end
  end

  @doc """
  Fetches all tags from AniList (single API call).
  """
  def fetch_all_tags do
    query = """
    query {
      MediaTagCollection {
        id
        name
        description
        category
        isGeneralSpoiler
        isAdult
      }
    }
    """

    body = Jason.encode!(%{"query" => query})

    case Req.post(@base_url,
           body: body,
           headers: [{"content-type", "application/json"}],
           receive_timeout: 30_000
         ) do
      {:ok, %{status: 200, body: %{"data" => %{"MediaTagCollection" => tags}}}} ->
        Logger.info("[TagsWorker] Fetched #{length(tags)} tags from AniList")
        {:ok, tags}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Inserts tags into the database.
  Uses upsert to handle duplicates.
  """
  def insert_tags(tags) when is_list(tags) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    # Transform tags
    tag_records =
      tags
      |> Enum.map(fn tag ->
        tag_attrs = Transformer.transform_tag(tag)

        Map.merge(tag_attrs, %{
          inserted_at: now,
          updated_at: now
        })
      end)

    # Batch insert with upsert
    {count, _} =
      Repo.insert_all(
        "tags",
        tag_records,
        prefix: "contents",
        on_conflict: {:replace, [:name_en, :description_en, :category, :is_general_spoiler, :is_adult, :updated_at]},
        conflict_target: [:anilist_id]
      )

    {:ok, count}
  rescue
    e ->
      {:error, {:insert_failed, e}}
  end
end
