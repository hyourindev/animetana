defmodule Yunaos.Jikan.Workers.MagazinesWorker do
  @moduledoc """
  Fetches all manga magazines/publishers from the Jikan API via paginated
  requests to `GET /magazines` and upserts them into the `magazines` table.
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  @rate_limit_ms 1_100

  def run do
    Logger.info("[MagazinesWorker] Starting magazine collection")

    total = Client.get_all_pages("/magazines", [], fn data, _page -> process_page(data) end)

    Logger.info("[MagazinesWorker] Finished. Processed #{inspect(total)} total pages")
    :ok
  end

  defp process_page(items) when is_list(items) do
    Logger.info("[MagazinesWorker] Processing batch of #{length(items)} magazines")

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries =
      items
      |> Enum.map(&map_magazine/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn entry -> Map.merge(entry, %{inserted_at: now, updated_at: now}) end)

    entries
    |> Enum.uniq_by(& &1.mal_id)
    |> Enum.chunk_every(50)
    |> Enum.each(fn batch ->
      Repo.insert_all("magazines", batch,
        on_conflict: {:replace, [:name, :url, :count, :updated_at]},
        conflict_target: :mal_id
      )
    end)

    Logger.info("[MagazinesWorker] Upserted #{length(entries)} magazines")
    Process.sleep(@rate_limit_ms)
  end

  defp map_magazine(item) do
    mal_id = item["mal_id"]
    name = item["name"]

    if is_nil(mal_id) or is_nil(name) do
      Logger.warning("[MagazinesWorker] Skipping item with missing mal_id or name: #{inspect(mal_id)}")
      nil
    else
      %{
        mal_id: mal_id,
        name: name,
        url: item["url"],
        count: item["count"] || 0
      }
    end
  end
end
