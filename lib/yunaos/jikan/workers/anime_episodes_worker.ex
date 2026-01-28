defmodule Yunaos.Jikan.Workers.AnimeEpisodesWorker do
  @moduledoc """
  Phase 3 worker: For each anime of type TV, OVA, or ONA, fetches all
  episode pages (`GET /anime/{mal_id}/episodes`) using `get_all_pages`
  and upserts each episode into the `episodes` table.
  """

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.Client

  import Ecto.Query

  @rate_limit_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Entry point. Iterates over TV/OVA/ONA anime and fetches episodes for each."
  def run do
    Logger.info("[AnimeEpisodesWorker] Starting anime episodes sync")

    anime_list =
      Repo.all(
        from(a in "anime",
          where: a.type in ["tv", "ova", "ona"],
          select: {a.id, a.mal_id}
        )
      )

    total = length(anime_list)
    Logger.info("[AnimeEpisodesWorker] Found #{total} anime (tv/ova/ona) to process")

    anime_list
    |> Enum.with_index(1)
    |> Enum.each(fn {{anime_id, mal_id}, index} ->
      try do
        Logger.info("[AnimeEpisodesWorker] [#{index}/#{total}] Processing anime mal_id=#{mal_id}")
        process_anime(anime_id, mal_id)
      rescue
        e ->
          Logger.error(
            "[AnimeEpisodesWorker] Failed for anime mal_id=#{mal_id}: #{inspect(e)}"
          )
      end

      Process.sleep(@rate_limit_ms)
    end)

    Logger.info("[AnimeEpisodesWorker] Anime episodes sync complete")
    :ok
  end

  # ---------------------------------------------------------------------------
  # Processing
  # ---------------------------------------------------------------------------

  defp process_anime(anime_id, mal_id) do
    Client.get_all_pages("/anime/#{mal_id}/episodes", [], fn page_data, _page_number ->
      Logger.debug(
        "[AnimeEpisodesWorker] Processing #{length(page_data)} episodes for mal_id=#{mal_id}"
      )

      upsert_episodes(anime_id, page_data)
    end)
  end

  defp upsert_episodes(anime_id, episodes) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries =
      episodes
      |> Enum.map(fn ep -> map_episode(anime_id, ep, now) end)
      |> Enum.reject(&is_nil/1)

    entries
    |> Enum.uniq_by(&{&1.anime_id, &1.episode_number})
    |> Enum.chunk_every(50)
    |> Enum.each(fn batch ->
      Repo.insert_all("episodes", batch,
        on_conflict:
          {:replace,
           [:mal_id, :title, :title_japanese, :title_romaji, :aired,
            :average_rating, :is_filler, :is_recap, :updated_at]},
        conflict_target: [:anime_id, :episode_number]
      )
    end)
  end

  defp map_episode(anime_id, ep, now) do
    episode_number = ep["mal_id"]

    if is_nil(episode_number) do
      Logger.warning("[AnimeEpisodesWorker] Skipping episode with nil mal_id for anime_id=#{anime_id}")
      nil
    else
      %{
        anime_id: anime_id,
        mal_id: episode_number,
        episode_number: Decimal.new(episode_number),
        title: ep["title"],
        title_japanese: ep["title_japanese"],
        title_romaji: ep["title_romanji"],
        aired: parse_date(ep["aired"]),
        average_rating: ep["score"],
        is_filler: ep["filler"] || false,
        is_recap: ep["recap"] || false,
        inserted_at: now,
        updated_at: now
      }
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp parse_date(nil), do: nil

  defp parse_date(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, dt, _offset} ->
        DateTime.to_date(dt)

      {:error, _} ->
        case Date.from_iso8601(String.slice(datetime_string, 0, 10)) do
          {:ok, date} -> date
          {:error, _} -> nil
        end
    end
  end

  defp parse_date(_), do: nil
end
