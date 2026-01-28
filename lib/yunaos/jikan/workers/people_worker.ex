defmodule Yunaos.Jikan.Workers.PeopleWorker do
  @moduledoc """
  Fetches all people (voice actors, directors, writers, composers, etc.) from
  the Jikan API via paginated requests to `GET /people` and upserts them into
  the `people` table.
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  @rate_limit_ms 1_100

  def run do
    Logger.info("[PeopleWorker] Starting people collection")

    total = Client.get_all_pages("/people", [], fn data, _page -> process_page(data) end)

    Logger.info("[PeopleWorker] Finished. Processed #{inspect(total)} total pages")
    :ok
  end

  defp process_page(items) when is_list(items) do
    Logger.info("[PeopleWorker] Processing batch of #{length(items)} people")

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries =
      items
      |> Enum.map(&map_person/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn entry -> Map.merge(entry, %{inserted_at: now, updated_at: now}) end)

    entries
    |> Enum.uniq_by(& &1.mal_id)
    |> Enum.chunk_every(50)
    |> Enum.each(fn batch ->
      Repo.insert_all("people", batch,
        on_conflict:
          {:replace,
           [
             :name,
             :given_name,
             :family_name,
             :alternate_names,
             :birthday,
             :website_url,
             :image_url,
             :about,
             :favorites_count,
             :updated_at
           ]},
        conflict_target: :mal_id
      )
    end)

    Logger.info("[PeopleWorker] Upserted #{length(entries)} people")
    Process.sleep(@rate_limit_ms)
  end

  defp map_person(item) do
    mal_id = item["mal_id"]
    name = item["name"]

    if is_nil(mal_id) or is_nil(name) do
      Logger.warning("[PeopleWorker] Skipping item with missing mal_id or name: #{inspect(mal_id)}")
      nil
    else
      %{
        mal_id: mal_id,
        name: name,
        given_name: item["given_name"],
        family_name: item["family_name"],
        alternate_names: item["alternate_names"] || [],
        birthday: parse_date(item["birthday"]),
        website_url: item["website_url"],
        image_url: get_in(item, ["images", "jpg", "image_url"]),
        about: item["about"],
        favorites_count: item["favorites"] || 0
      }
    end
  end

  defp parse_date(nil), do: nil

  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(String.slice(date_string, 0, 10)) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end

  defp parse_date(_), do: nil
end
