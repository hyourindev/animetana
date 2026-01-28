defmodule Yunaos.Jikan.Workers.StudiosWorker do
  @moduledoc """
  Fetches all producers/studios from the Jikan API via paginated requests
  to `GET /producers` and upserts them into the `studios` table.
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  @rate_limit_ms 1_100

  def run do
    Logger.info("[StudiosWorker] Starting studio/producer collection")

    total = Client.get_all_pages("/producers", [], fn data, _page -> process_page(data) end)

    Logger.info("[StudiosWorker] Finished. Processed #{inspect(total)} total pages")
    :ok
  end

  defp process_page(items) when is_list(items) do
    Logger.info("[StudiosWorker] Processing batch of #{length(items)} studios")

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries =
      items
      |> Enum.map(&map_studio/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn entry -> Map.merge(entry, %{inserted_at: now, updated_at: now}) end)

    entries
    |> Enum.uniq_by(& &1.mal_id)
    |> Enum.chunk_every(50)
    |> Enum.each(fn batch ->
      Repo.insert_all("studios", batch,
        on_conflict: {:replace, [:name, :type, :established, :website_url, :about, :updated_at]},
        conflict_target: :mal_id
      )
    end)

    Logger.info("[StudiosWorker] Upserted #{length(entries)} studios")
    Process.sleep(@rate_limit_ms)
  end

  defp map_studio(item) do
    mal_id = item["mal_id"]

    name =
      item
      |> get_in(["titles"])
      |> find_default_title()

    established = parse_date(item["established"])
    about = item["about"]
    website_url = extract_website_url(item)

    if is_nil(mal_id) or is_nil(name) do
      Logger.warning("[StudiosWorker] Skipping item with missing mal_id or name: #{inspect(mal_id)}")
      nil
    else
      %{
        mal_id: mal_id,
        name: name,
        type: "studio",
        established: established,
        website_url: website_url,
        about: about
      }
    end
  end

  defp find_default_title(nil), do: nil

  defp find_default_title(titles) do
    case Enum.find(titles, fn t -> t["type"] == "Default" end) do
      nil -> List.first(titles) |> then(fn t -> t && t["title"] end)
      title -> title["title"]
    end
  end

  defp extract_website_url(item) do
    # The website_url from the titles, not the MAL url
    # Producers endpoint may include external URLs in the item
    item["url"]
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
