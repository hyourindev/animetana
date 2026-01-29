defmodule Animetana.Anilist.Workers.CatalogWorker do
  @moduledoc """
  Pages through all anime/manga from AniList and populates our database.

  Each page (50 items) includes nested data:
  - Characters with voice actors
  - Staff
  - Studios (anime only)
  - Relations
  - Recommendations
  - Rankings
  - Score/Status distributions

  Rate limit: ~86 requests/minute
  """

  require Logger

  import Ecto.Query

  alias Animetana.Anilist.Transformer
  alias Animetana.Repo

  @base_url "https://graphql.anilist.co"
  @per_page 50
  @rate_limit_ms 700  # ~86 req/min (90 limit, 86 to be safe)

  # ===========================================================================
  # PUBLIC API
  # ===========================================================================

  @doc """
  Runs the catalog worker for a specific media type.

  ## Options
    - `:start_page` - Page to start from (default: 1)
    - `:end_page` - Page to stop at (default: nil = all pages)
    - `:on_page` - Callback function called after each page with {page, count}

  ## Examples

      # Fetch all anime
      CatalogWorker.run(:anime)

      # Fetch pages 1-10 of manga
      CatalogWorker.run(:manga, start_page: 1, end_page: 10)
  """
  def run(media_type, opts \\ []) when media_type in [:anime, :manga] do
    start_page = Keyword.get(opts, :start_page, 1)
    end_page = Keyword.get(opts, :end_page, nil)
    on_page = Keyword.get(opts, :on_page, fn _, _ -> :ok end)

    Logger.info("[CatalogWorker] Starting #{media_type} catalog from page #{start_page}")

    type_str = media_type |> Atom.to_string() |> String.upcase()

    fetch_pages(type_str, media_type, start_page, end_page, on_page, 0)
  end

  @doc """
  Fetches a single page and processes it. Useful for testing.
  """
  def fetch_single_page(media_type, page) when media_type in [:anime, :manga] do
    type_str = media_type |> Atom.to_string() |> String.upcase()

    case fetch_page(type_str, page) do
      {:ok, %{"Page" => %{"media" => media, "pageInfo" => info}}} ->
        process_page(media, media_type)
        {:ok, %{page: page, count: length(media), total: info["total"], last_page: info["lastPage"]}}

      {:error, _} = err ->
        err
    end
  end

  # ===========================================================================
  # PAGINATION
  # ===========================================================================

  defp fetch_pages(type_str, media_type, page, end_page, on_page, total_processed) do
    # Check if we should stop
    if end_page && page > end_page do
      Logger.info("[CatalogWorker] Reached end_page #{end_page}, stopping")
      {:ok, total_processed}
    else
      Process.sleep(@rate_limit_ms)

      case fetch_page(type_str, page) do
        {:ok, %{"Page" => %{"pageInfo" => info, "media" => media}}} ->
          count = length(media)
          new_total = total_processed + count

          Logger.info("[CatalogWorker] Page #{page}/#{info["lastPage"]} - #{count} items (total: #{new_total}/#{info["total"]})")

          # Process the page
          process_page(media, media_type)

          # Callback
          on_page.(page, count)

          # Continue if there's more
          if info["hasNextPage"] do
            fetch_pages(type_str, media_type, page + 1, end_page, on_page, new_total)
          else
            Logger.info("[CatalogWorker] Completed! Processed #{new_total} #{media_type} items")
            {:ok, new_total}
          end

        {:error, reason} ->
          Logger.error("[CatalogWorker] Failed at page #{page}: #{inspect(reason)}")
          {:error, reason, page}
      end
    end
  end

  defp fetch_page(type_str, page, retries \\ 3) do
    query = File.read!("lib/Animetana/anilist/queries/media_page.graphql")

    body = Jason.encode!(%{
      "query" => query,
      "variables" => %{"page" => page, "perPage" => @per_page, "type" => type_str}
    })

    case Req.post(@base_url,
           body: body,
           headers: [{"content-type", "application/json"}],
           receive_timeout: 120_000
         ) do
      {:ok, %{status: 200, body: %{"data" => data}}} ->
        {:ok, data}

      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        # Response was truncated or invalid JSON
        if retries > 0 do
          Logger.warning("[CatalogWorker] Got truncated response, retrying page #{page}...")
          Process.sleep(2000)
          fetch_page(type_str, page, retries - 1)
        else
          {:error, {:truncated_response, page}}
        end

      {:ok, %{status: 429, headers: headers}} ->
        retry_after = get_retry_after(headers)
        Logger.warning("[CatalogWorker] Rate limited, waiting #{retry_after}s...")
        Process.sleep(retry_after * 1000)
        fetch_page(type_str, page, retries)

      {:ok, %{status: status, body: body}} when status >= 500 ->
        if retries > 0 do
          Logger.warning("[CatalogWorker] Server error #{status}, retrying page #{page} in 5s...")
          Process.sleep(5000)
          fetch_page(type_str, page, retries - 1)
        else
          {:error, {:http_error, status, body}}
        end

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        if retries > 0 do
          Logger.warning("[CatalogWorker] Request failed, retrying page #{page}...")
          Process.sleep(2000)
          fetch_page(type_str, page, retries - 1)
        else
          {:error, reason}
        end
    end
  end

  defp get_retry_after(headers) do
    case Enum.find(headers, fn {k, _} -> String.downcase(k) == "retry-after" end) do
      {_, value} -> String.to_integer(value)
      nil -> 60
    end
  end

  # ===========================================================================
  # PAGE PROCESSING
  # ===========================================================================

  defp process_page(media_list, media_type) do
    Enum.each(media_list, fn media_data ->
      process_single_media(media_data, media_type)
    end)
  end

  defp process_single_media(data, media_type) do
    Repo.transaction(fn ->
      # 1. Extract and upsert tags
      tag_data = upsert_tags(data)

      # 2. Extract and upsert studios (anime only)
      studio_data = if media_type == :anime, do: extract_studios(data), else: []

      # 3. Extract and upsert people (staff + voice actors)
      people_data = extract_people(data)

      # 4. Extract and upsert characters
      character_data = extract_characters(data)

      # 5. Upsert the main anime/manga record
      media_id = upsert_media(data, media_type)

      # 6. Create junction table entries
      if media_id do
        create_media_tags(media_id, tag_data, media_type)
        create_media_studios(media_id, studio_data, media_type)
        create_media_staff(media_id, people_data[:staff], media_type)
        create_media_characters(media_id, character_data, data, media_type)
        create_relations(media_id, data, media_type)

        # 7. Airing schedule & episodes (anime only)
        if media_type == :anime do
          create_airing_schedule(media_id, data)
          create_episodes_from_streaming(media_id, data)
        end
      end

      media_id
    end)
  end

  # ===========================================================================
  # UPSERT FUNCTIONS
  # ===========================================================================

  defp upsert_tags(data) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    tags = data["tags"] || []

    # Upsert tags and return both tag_id and junction table info (rank, is_spoiler)
    tags
    |> Enum.map(fn tag ->
      tag_attrs = Transformer.transform_tag(tag)
      attrs = Map.merge(tag_attrs, %{inserted_at: now, updated_at: now})

      tag_id =
        case Repo.insert_all(
               "tags",
               [attrs],
               prefix: "contents",
               on_conflict: {:replace, [:name_en, :description_en, :category, :is_general_spoiler, :is_adult, :updated_at]},
               conflict_target: [:anilist_id],
               returning: [:id]
             ) do
          {_, [%{id: id}]} -> id
          _ -> nil
        end

      if tag_id do
        info = Transformer.extract_tag_info(tag)
        %{tag_id: tag_id, rank: info.rank, is_spoiler: info.is_spoiler}
      else
        nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp extract_studios(data) do
    edges = get_in(data, ["studios", "edges"]) || []

    Enum.map(edges, fn edge ->
      studio = Transformer.transform_studio(edge)
      role = Transformer.extract_studio_role(edge)

      %{studio: studio, role: role}
    end)
  end

  defp extract_people(data) do
    staff_edges = get_in(data, ["staff", "edges"]) || []
    char_edges = get_in(data, ["characters", "edges"]) || []

    # Staff members
    staff =
      staff_edges
      |> Enum.map(fn edge ->
        person = Transformer.transform_person(edge)
        role = edge["role"]

        %{person: person, role: role}
      end)

    # Voice actors from characters
    voice_actors =
      char_edges
      |> Enum.flat_map(fn char_edge ->
        Transformer.extract_voice_actor_roles(char_edge)
        |> Enum.map(fn va_role ->
          %{person: va_role.voice_actor, role: "Voice Actor", language: va_role.language}
        end)
      end)

    %{staff: staff, voice_actors: voice_actors}
  end

  defp extract_characters(data) do
    edges = get_in(data, ["characters", "edges"]) || []

    Enum.map(edges, fn edge ->
      character = Transformer.transform_character(edge)
      role = Transformer.extract_character_role(edge)
      voice_actors = Transformer.extract_voice_actor_roles(edge)

      %{character: character, role: role, voice_actors: voice_actors}
    end)
  end

  defp upsert_media(data, :anime) do
    attrs = Transformer.transform_anime(data)
    upsert_record("anime", attrs, :anilist_id)
  end

  defp upsert_media(data, :manga) do
    attrs = Transformer.transform_manga(data)
    upsert_record("manga", attrs, :anilist_id)
  end

  defp upsert_record(table, attrs, conflict_key) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    attrs = Map.merge(attrs, %{inserted_at: now, updated_at: now})

    # Get all keys except id, inserted_at for the update
    update_keys = Map.keys(attrs) -- [:id, :inserted_at, conflict_key]

    case Repo.insert_all(
           table,
           [attrs],
           prefix: "contents",
           on_conflict: {:replace, update_keys},
           conflict_target: [conflict_key],
           returning: [:id]
         ) do
      {_, [%{id: id}]} -> id
      _ -> nil
    end
  end

  # ===========================================================================
  # JUNCTION TABLE CREATION
  # ===========================================================================

  defp create_media_tags(media_id, tag_data, media_type) do
    table = if media_type == :anime, do: "anime_tags", else: "manga_tags"
    fk = if media_type == :anime, do: :anime_id, else: :manga_id

    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    entries =
      tag_data
      |> Enum.uniq_by(& &1.tag_id)
      |> Enum.map(fn %{tag_id: tag_id, rank: rank, is_spoiler: is_spoiler} ->
        %{
          fk => media_id,
          tag_id: tag_id,
          rank: rank,
          is_spoiler: is_spoiler,
          inserted_at: now
        }
      end)

    if length(entries) > 0 do
      Repo.insert_all(
        table,
        entries,
        prefix: "contents",
        on_conflict: {:replace, [:rank, :is_spoiler]},
        conflict_target: [fk, :tag_id]
      )
    end
  end

  defp create_media_studios(media_id, studio_data, :anime) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Enum.each(studio_data, fn %{studio: studio, role: role} ->
      # Upsert studio
      studio_attrs = Map.merge(studio, %{inserted_at: now, updated_at: now})

      studio_id =
        case Repo.insert_all(
               "studios",
               [studio_attrs],
               prefix: "contents",
               on_conflict: {:replace, [:name_en, :is_animation_studio, :favorites_count, :updated_at]},
               conflict_target: [:anilist_id],
               returning: [:id]
             ) do
          {_, [%{id: id}]} -> id
          _ -> nil
        end

      # Create junction
      if studio_id do
        Repo.insert_all(
          "anime_studios",
          [%{anime_id: media_id, studio_id: studio_id, role: role, inserted_at: now}],
          prefix: "contents",
          on_conflict: {:replace, [:role]},
          conflict_target: [:anime_id, :studio_id]
        )
      end
    end)
  end

  defp create_media_studios(_, _, :manga), do: :ok

  defp create_media_staff(media_id, staff_data, media_type) do
    table = if media_type == :anime, do: "anime_staff", else: "manga_staff"
    fk = if media_type == :anime, do: :anime_id, else: :manga_id

    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Enum.each(staff_data, fn %{person: person, role: role} ->
      # Truncate role if too long (max 200 chars)
      role = if role && byte_size(role) > 200, do: String.slice(role, 0, 197) <> "...", else: role
      # Upsert person
      person_attrs = Map.merge(person, %{inserted_at: now, updated_at: now})

      person_id =
        case Repo.insert_all(
               "people",
               [person_attrs],
               prefix: "contents",
               on_conflict: {:replace, [:name_en, :name_ja, :about_en, :image_large, :image_medium, :favorites_count, :updated_at]},
               conflict_target: [:anilist_id],
               returning: [:id]
             ) do
          {_, [%{id: id}]} -> id
          _ -> nil
        end

      # Create junction (unique on anime_id/manga_id, person_id, role)
      if person_id do
        Repo.insert_all(
          table,
          [%{fk => media_id, person_id: person_id, role: role, inserted_at: now}],
          prefix: "contents",
          on_conflict: :nothing,
          conflict_target: [fk, :person_id, :role]
        )
      end
    end)
  end

  defp create_media_characters(media_id, character_data, _data, media_type) do
    char_table = if media_type == :anime, do: "anime_characters", else: "manga_characters"
    fk = if media_type == :anime, do: :anime_id, else: :manga_id

    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Enum.each(character_data, fn %{character: character, role: role, voice_actors: voice_actors} ->
      # Upsert character
      char_attrs = Map.merge(character, %{inserted_at: now, updated_at: now})

      char_id =
        case Repo.insert_all(
               "characters",
               [char_attrs],
               prefix: "contents",
               on_conflict: {:replace, [:name_en, :name_ja, :about_en, :image_large, :image_medium, :favorites_count, :updated_at]},
               conflict_target: [:anilist_id],
               returning: [:id]
             ) do
          {_, [%{id: id}]} -> id
          _ -> nil
        end

      if char_id do
        # Create character junction
        Repo.insert_all(
          char_table,
          [%{fk => media_id, character_id: char_id, role: role, inserted_at: now}],
          prefix: "contents",
          on_conflict: {:replace, [:role]},
          conflict_target: [fk, :character_id]
        )

        # Create voice actor junctions (anime only)
        if media_type == :anime do
          Enum.each(voice_actors, fn va_role ->
            # Upsert voice actor
            va_attrs = Map.merge(va_role.voice_actor, %{inserted_at: now, updated_at: now})

            va_id =
              case Repo.insert_all(
                     "people",
                     [va_attrs],
                     prefix: "contents",
                     on_conflict: {:replace, [:name_en, :name_ja, :about_en, :image_large, :image_medium, :favorites_count, :updated_at]},
                     conflict_target: [:anilist_id],
                     returning: [:id]
                   ) do
                {_, [%{id: id}]} -> id
                _ -> nil
              end

            if va_id do
              Repo.insert_all(
                "character_voice_actors",
                [%{
                  anime_id: media_id,
                  character_id: char_id,
                  person_id: va_id,
                  language: va_role.language || "japanese",
                  role_notes: va_role.role_notes,
                  dub_group: va_role.dub_group,
                  inserted_at: now
                }],
                prefix: "contents",
                on_conflict: {:replace, [:role_notes, :dub_group]},
                conflict_target: [:anime_id, :character_id, :person_id, :language]
              )
            end
          end)
        end
      end
    end)
  end

  defp create_relations(media_id, data, media_type) do
    edges = get_in(data, ["relations", "edges"]) || []
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    source_key = if media_type == :anime, do: :source_anime_id, else: :source_manga_id

    Enum.each(edges, fn edge ->
      rel = Transformer.transform_relation(edge)

      # Determine target key based on type
      target_key = if rel.target_type == "anime", do: :target_anime_id, else: :target_manga_id

      # We need to find or create the target media by anilist_id
      # For now, we'll store the relation with null target if it doesn't exist yet
      # The target will be filled in when we process that media

      target_table = if rel.target_type == "anime", do: "anime", else: "manga"
      target_anilist_id = rel.target_anilist_id
      query = from(m in target_table, prefix: "contents")
      query = where(query, [m], m.anilist_id == ^target_anilist_id)
      query = select(query, [m], m.id)
      target_id = Repo.one(query)

      if target_id do
        entry = %{
          source_key => media_id,
          target_key => target_id,
          relation_type: rel.relation_type,
          inserted_at: now
        }

        # Build conflict target based on which keys are set
        # The unique constraint uses NULLS NOT DISTINCT so we include all columns
        Repo.insert_all(
          "content_relations",
          [entry],
          prefix: "contents",
          on_conflict: :nothing,
          conflict_target: {:unsafe_fragment, "(source_anime_id, source_manga_id, target_anime_id, target_manga_id, relation_type)"}
        )
      end
    end)
  end

  # ===========================================================================
  # AIRING SCHEDULE (anime only)
  # ===========================================================================

  defp create_airing_schedule(anime_id, data) do
    nodes = get_in(data, ["airingSchedule", "nodes"]) || []
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    entries =
      nodes
      |> Enum.filter(fn node -> node["episode"] && node["episode"] > 0 && node["airingAt"] end)
      |> Enum.map(fn node ->
        %{
          anime_id: anime_id,
          anilist_id: node["id"],
          episode: node["episode"],
          airing_at: DateTime.from_unix!(node["airingAt"]) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second),
          inserted_at: now
        }
      end)

    if length(entries) > 0 do
      Repo.insert_all(
        "airing_schedule",
        entries,
        prefix: "contents",
        on_conflict: {:replace, [:anilist_id, :airing_at]},
        conflict_target: [:anime_id, :episode]
      )
    end
  end

  # ===========================================================================
  # EPISODES FROM STREAMING EPISODES (anime only)
  # Creates basic episode records from streaming episode data
  # ===========================================================================

  defp create_episodes_from_streaming(anime_id, data) do
    streaming_eps = data["streamingEpisodes"] || []
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    # Try to extract episode numbers from streaming episode titles
    # Format is usually "Episode 1 - Title" or "1. Title" etc.
    entries =
      streaming_eps
      |> Enum.map(fn ep ->
        episode_num = extract_episode_number(ep["title"])

        # Only create entry if we got a valid episode number > 0
        if episode_num && episode_num > 0 do
          %{
            anime_id: anime_id,
            episode_number: episode_num,
            title_en: clean_episode_title(ep["title"]),
            thumbnail_url: ep["thumbnail"],
            inserted_at: now,
            updated_at: now
          }
        else
          nil
        end
      end)
      |> Enum.filter(& &1)
      |> Enum.uniq_by(& &1.episode_number)

    if length(entries) > 0 do
      Repo.insert_all(
        "episodes",
        entries,
        prefix: "contents",
        on_conflict: {:replace, [:title_en, :thumbnail_url, :updated_at]},
        conflict_target: [:anime_id, :episode_number]
      )
    end
  end

  # Extract episode number from title like "Episode 1 - Title" or "1. Title"
  defp extract_episode_number(nil), do: nil
  defp extract_episode_number(title) do
    cond do
      # "Episode 1" or "Episode 1 - Title"
      match = Regex.run(~r/Episode\s+(\d+)/i, title) ->
        String.to_integer(Enum.at(match, 1))

      # "1. Title" or "1 - Title"
      match = Regex.run(~r/^(\d+)[\.\s\-]/, title) ->
        String.to_integer(Enum.at(match, 1))

      # "E01" or "EP01"
      match = Regex.run(~r/E[Pp]?(\d+)/i, title) ->
        String.to_integer(Enum.at(match, 1))

      true ->
        nil
    end
  end

  # Clean title by removing episode number prefix
  defp clean_episode_title(nil), do: nil
  defp clean_episode_title(title) do
    title
    |> String.replace(~r/^Episode\s+\d+\s*[-:]\s*/i, "")
    |> String.replace(~r/^\d+[\.\s\-]+/, "")
    |> String.trim()
    |> case do
      "" -> title  # If nothing left, return original
      cleaned -> cleaned
    end
  end
end
