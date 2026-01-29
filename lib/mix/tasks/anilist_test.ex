defmodule Mix.Tasks.AnilistTest do
  @moduledoc """
  Test AniList GraphQL queries.

  ## Usage

      mix anilist_test anime 1         # Fetch anime by AniList ID
      mix anilist_test anime_mal 1     # Fetch anime by MAL ID
      mix anilist_test manga 1         # Fetch manga by AniList ID
      mix anilist_test manga_mal 1     # Fetch manga by MAL ID
      mix anilist_test enums           # Fetch all AniList enum types
      mix anilist_test tags            # Fetch all tags (single call)
      mix anilist_test page anime 1    # Fetch page 1 of anime (50 items)
      mix anilist_test page manga 1    # Fetch page 1 of manga (50 items)
      mix anilist_test check anime     # Check page 1 anime against our schema
      mix anilist_test check manga     # Check page 1 manga against our schema
  """

  use Mix.Task

  require Logger

  @base_url "https://graphql.anilist.co"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    case args do
      ["anime", id] ->
        fetch_media_full(:anime, String.to_integer(id), :anilist)

      ["anime_mal", mal_id] ->
        fetch_media_full(:anime, String.to_integer(mal_id), :mal)

      ["manga", id] ->
        fetch_media_full(:manga, String.to_integer(id), :anilist)

      ["manga_mal", mal_id] ->
        fetch_media_full(:manga, String.to_integer(mal_id), :mal)

      ["enums"] ->
        fetch_all_enums()

      ["tags"] ->
        fetch_all_tags()

      ["page", type, page_num] ->
        media_type = String.upcase(type)
        fetch_media_page(media_type, String.to_integer(page_num))

      ["check", type] ->
        media_type = String.upcase(type)
        check_schema_mapping(media_type)

      _ ->
        IO.puts("""
        Usage:
          mix anilist_test anime <anilist_id>     # Fetch anime by AniList ID
          mix anilist_test anime_mal <mal_id>     # Fetch anime by MAL ID
          mix anilist_test manga <anilist_id>     # Fetch manga by AniList ID
          mix anilist_test manga_mal <mal_id>     # Fetch manga by MAL ID
          mix anilist_test enums                  # Fetch all AniList enum types
          mix anilist_test tags                   # Fetch all tags (single call)
          mix anilist_test page anime 1           # Fetch page of anime
          mix anilist_test page manga 1           # Fetch page of manga
          mix anilist_test check anime            # Check anime against our schema
          mix anilist_test check manga            # Check manga against our schema
        """)
    end
  end

  # ===========================================================================
  # TAGS - Single call to get all ~300 tags
  # ===========================================================================
  defp fetch_all_tags do
    query = File.read!("lib/yunaos/anilist/queries/tags_collection.graphql")

    IO.puts("\n=== Fetching ALL AniList Tags ===\n")

    case do_query(query, %{}) do
      {:ok, %{"MediaTagCollection" => tags}} ->
        IO.puts("Total tags: #{length(tags)}\n")

        # Group by category
        by_category = Enum.group_by(tags, & &1["category"])

        Enum.each(by_category, fn {category, cat_tags} ->
          IO.puts("#{category || "Uncategorized"} (#{length(cat_tags)}):")
          cat_tags
          |> Enum.take(5)
          |> Enum.each(fn tag ->
            spoiler = if tag["isGeneralSpoiler"], do: " [SPOILER]", else: ""
            adult = if tag["isAdult"], do: " [ADULT]", else: ""
            IO.puts("  - #{tag["name"]} (ID: #{tag["id"]})#{spoiler}#{adult}")
          end)
          if length(cat_tags) > 5, do: IO.puts("  ... and #{length(cat_tags) - 5} more")
          IO.puts("")
        end)

        # Save to file
        File.write!("anilist_tags.json", Jason.encode!(tags, pretty: true))
        IO.puts("[Saved to anilist_tags.json]")

      {:error, reason} ->
        IO.puts("Error: #{inspect(reason)}")
    end
  end

  # ===========================================================================
  # PAGE - Fetch a page of media (50 items with full data)
  # ===========================================================================
  defp fetch_media_page(media_type, page) do
    query = File.read!("lib/yunaos/anilist/queries/media_page.graphql")

    IO.puts("\n=== Fetching #{media_type} Page #{page} ===\n")

    case do_query(query, %{"page" => page, "perPage" => 50, "type" => media_type}) do
      {:ok, %{"Page" => %{"pageInfo" => info, "media" => media}}} ->
        IO.puts("Page #{info["currentPage"]}/#{info["lastPage"]} (#{info["total"]} total)")
        IO.puts("Fetched: #{length(media)} items\n")

        # Show first few items
        media
        |> Enum.take(5)
        |> Enum.each(fn m ->
          title = m["title"]["english"] || m["title"]["romaji"]
          IO.puts("#{m["id"]} | MAL:#{m["idMal"]} | #{m["format"]} | #{title}")

          # Show nested counts
          chars = get_in(m, ["characters", "pageInfo", "total"]) || 0
          staff = get_in(m, ["staff", "pageInfo", "total"]) || 0
          studios = length(get_in(m, ["studios", "edges"]) || [])
          relations = length(get_in(m, ["relations", "edges"]) || [])
          tags = length(m["tags"] || [])
          genres = length(m["genres"] || [])

          IO.puts("  -> chars:#{chars} staff:#{staff} studios:#{studios} relations:#{relations} tags:#{tags} genres:#{genres}")
        end)

        if length(media) > 5, do: IO.puts("... and #{length(media) - 5} more\n")

        # Save first item as sample
        sample = List.first(media)
        File.write!("anilist_#{String.downcase(media_type)}_sample.json", Jason.encode!(sample, pretty: true))
        IO.puts("[Sample saved to anilist_#{String.downcase(media_type)}_sample.json]")

        # Save full page
        File.write!("anilist_#{String.downcase(media_type)}_page_#{page}.json", Jason.encode!(media, pretty: true))
        IO.puts("[Full page saved to anilist_#{String.downcase(media_type)}_page_#{page}.json]")

      {:error, reason} ->
        IO.puts("Error: #{inspect(reason)}")
    end
  end

  # ===========================================================================
  # CHECK - Analyze data against our schema
  # ===========================================================================
  defp check_schema_mapping(media_type) do
    query = File.read!("lib/yunaos/anilist/queries/media_page.graphql")

    IO.puts("\n=== Checking #{media_type} Schema Mapping ===\n")

    case do_query(query, %{"page" => 1, "perPage" => 10, "type" => media_type}) do
      {:ok, %{"Page" => %{"media" => media}}} ->
        # Analyze all fields across the 10 items
        analyze_schema_coverage(media, media_type)

      {:error, reason} ->
        IO.puts("Error: #{inspect(reason)}")
    end
  end

  defp analyze_schema_coverage(media_list, media_type) do
    IO.puts("Analyzing #{length(media_list)} #{media_type} items...\n")

    # Our DB columns for anime/manga
    db_columns = if media_type == "ANIME" do
      ~w(
        id mal_id anilist_id kitsu_id
        title_en title_ja title_romaji title_synonyms
        synopsis_en synopsis_ja background_en background_ja
        format status source season season_year
        episodes duration broadcast_day broadcast_time
        start_date end_date next_airing_episode next_airing_at
        country_of_origin is_licensed is_adult hashtag
        cover_image_extra_large cover_image_large cover_image_medium cover_image_color banner_image
        trailer_id trailer_site trailer_thumbnail
        external_links streaming_links anilist_url mal_url
        yunaos_score_en yunaos_scored_by_en yunaos_rank_en yunaos_popularity_en yunaos_favorites_en yunaos_trending_en
        yunaos_score_ja yunaos_scored_by_ja yunaos_rank_ja yunaos_popularity_ja yunaos_favorites_ja yunaos_trending_ja
      )
    else
      ~w(
        id mal_id anilist_id kitsu_id
        title_en title_ja title_romaji title_synonyms
        synopsis_en synopsis_ja background_en background_ja
        format status source chapters volumes
        start_date end_date
        country_of_origin is_licensed is_adult hashtag
        cover_image_extra_large cover_image_large cover_image_medium cover_image_color banner_image
        external_links anilist_url mal_url
        yunaos_score_en yunaos_scored_by_en yunaos_rank_en yunaos_popularity_en yunaos_favorites_en yunaos_trending_en
        yunaos_score_ja yunaos_scored_by_ja yunaos_rank_ja yunaos_popularity_ja yunaos_favorites_ja yunaos_trending_ja
      )
    end

    # AniList -> DB mapping
    mapping = %{
      "id" => "anilist_id",
      "idMal" => "mal_id",
      "title.english" => "title_en",
      "title.native" => "title_ja",
      "title.romaji" => "title_romaji",
      "synonyms" => "title_synonyms",
      "description" => "synopsis_en",
      "format" => "format",
      "status" => "status",
      "source" => "source",
      "season" => "season",
      "seasonYear" => "season_year",
      "episodes" => "episodes",
      "chapters" => "chapters",
      "volumes" => "volumes",
      "duration" => "duration",
      "startDate" => "start_date",
      "endDate" => "end_date",
      "nextAiringEpisode.episode" => "next_airing_episode",
      "nextAiringEpisode.airingAt" => "next_airing_at",
      "countryOfOrigin" => "country_of_origin",
      "isLicensed" => "is_licensed",
      "isAdult" => "is_adult",
      "hashtag" => "hashtag",
      "coverImage.extraLarge" => "cover_image_extra_large",
      "coverImage.large" => "cover_image_large",
      "coverImage.medium" => "cover_image_medium",
      "coverImage.color" => "cover_image_color",
      "bannerImage" => "banner_image",
      "trailer.id" => "trailer_id",
      "trailer.site" => "trailer_site",
      "trailer.thumbnail" => "trailer_thumbnail",
      "externalLinks" => "external_links",
      "siteUrl" => "anilist_url",
      "averageScore" => "(not stored - AniList score)",
      "meanScore" => "(not stored - AniList score)",
      "popularity" => "(not stored - AniList popularity)",
      "favourites" => "(not stored - AniList favourites)",
      "trending" => "(not stored - AniList trending)",
      "genres" => "-> anime_genres / manga_genres junction",
      "tags" => "-> anime_tags / manga_tags junction",
      "studios" => "-> anime_studios junction",
      "staff" => "-> anime_staff junction + people table",
      "characters" => "-> anime_characters junction + characters table",
      "relations" => "-> content_relations table",
      "recommendations" => "-> anime_recommendations table",
      "rankings" => "-> anime_rankings table",
      "stats.scoreDistribution" => "-> anime_score_distributions table",
      "stats.statusDistribution" => "-> anime_status_distributions table"
    }

    IO.puts("=" |> String.duplicate(70))
    IO.puts("FIELD MAPPING: AniList -> Database")
    IO.puts("=" |> String.duplicate(70))

    # Check each AniList field
    sample = List.first(media_list)

    mapping
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.each(fn {anilist_field, db_field} ->
      value = get_nested_value(sample, anilist_field)
      has_value = value != nil && value != "" && value != []

      status = if has_value, do: "✓", else: "·"
      preview = format_value_preview(value)

      IO.puts("#{status} #{String.pad_trailing(anilist_field, 30)} -> #{db_field}")
      if has_value && preview != "", do: IO.puts("    #{preview}")
    end)

    # Check nested data counts
    IO.puts("\n" <> String.duplicate("=", 70))
    IO.puts("NESTED DATA COUNTS (across #{length(media_list)} items)")
    IO.puts(String.duplicate("=", 70))

    totals = Enum.reduce(media_list, %{chars: 0, staff: 0, studios: 0, rels: 0, recs: 0, tags: 0, genres: 0, rankings: 0}, fn m, acc ->
      %{
        chars: acc.chars + (get_in(m, ["characters", "pageInfo", "total"]) || 0),
        staff: acc.staff + (get_in(m, ["staff", "pageInfo", "total"]) || 0),
        studios: acc.studios + length(get_in(m, ["studios", "edges"]) || []),
        rels: acc.rels + length(get_in(m, ["relations", "edges"]) || []),
        recs: acc.recs + length(get_in(m, ["recommendations", "edges"]) || []),
        tags: acc.tags + length(m["tags"] || []),
        genres: acc.genres + length(m["genres"] || []),
        rankings: acc.rankings + length(m["rankings"] || [])
      }
    end)

    IO.puts("Characters:      #{totals.chars} total (avg #{div(totals.chars, length(media_list))} per item)")
    IO.puts("Staff:           #{totals.staff} total (avg #{div(totals.staff, length(media_list))} per item)")
    IO.puts("Studios:         #{totals.studios} total")
    IO.puts("Relations:       #{totals.rels} total")
    IO.puts("Recommendations: #{totals.recs} total")
    IO.puts("Tags:            #{totals.tags} total (avg #{div(totals.tags, length(media_list))} per item)")
    IO.puts("Genres:          #{totals.genres} total (avg #{div(totals.genres, length(media_list))} per item)")
    IO.puts("Rankings:        #{totals.rankings} total")

    IO.puts("\n✓ = has data, · = null/empty")
  end

  defp get_nested_value(map, key) do
    keys = String.split(key, ".")
    get_in(map, keys)
  end

  defp format_value_preview(nil), do: ""
  defp format_value_preview(""), do: ""
  defp format_value_preview([]), do: ""
  defp format_value_preview(value) when is_binary(value) do
    truncated = if String.length(value) > 60, do: String.slice(value, 0, 60) <> "...", else: value
    "\"#{truncated}\""
  end
  defp format_value_preview(value) when is_list(value), do: "[#{length(value)} items]"
  defp format_value_preview(value) when is_map(value), do: "{...}"
  defp format_value_preview(value), do: inspect(value)

  # ===========================================================================
  # HTTP Helper
  # ===========================================================================
  defp do_query(query, variables) do
    body = Jason.encode!(%{"query" => query, "variables" => variables})

    case Req.post(@base_url,
           body: body,
           headers: [{"content-type", "application/json"}],
           receive_timeout: 30_000
         ) do
      {:ok, %{status: 200, body: %{"data" => data}}} ->
        {:ok, data}

      {:ok, %{status: 200, body: %{"errors" => errors}}} ->
        {:error, {:graphql_errors, errors}}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_all_enums do
    query = File.read!("lib/yunaos/anilist/queries/introspect_enums.graphql")

    IO.puts("\n=== Fetching AniList Enum Types ===\n")

    body = Jason.encode!(%{"query" => query})

    case Req.post("https://graphql.anilist.co",
           body: body,
           headers: [{"content-type", "application/json"}],
           receive_timeout: 30_000
         ) do
      {:ok, %{status: 200, body: %{"data" => data}}} ->
        print_enums_comparison(data)

        # Save full response to file
        output_file = "anilist_enums.json"
        File.write!(output_file, Jason.encode!(data, pretty: true))
        IO.puts("\n[Full response saved to #{output_file}]")

      {:ok, %{status: status, body: body}} ->
        IO.puts("Error: HTTP #{status}")
        IO.inspect(body)

      {:error, reason} ->
        IO.puts("Error: #{inspect(reason)}")
    end
  end

  defp print_enums_comparison(data) do
    # Define your DB enums for comparison
    db_enums = %{
      "MediaFormat" => %{
        db_name: "contents.anime_type / contents.manga_type",
        db_values: ~w(tv movie ova ona special tv_special music cm pv unknown manga manhwa manhua light_novel novel one_shot doujinshi)
      },
      "MediaStatus" => %{
        db_name: "contents.anime_status / contents.manga_status",
        db_values: ~w(airing finished upcoming unknown publishing hiatus discontinued)
      },
      "MediaSeason" => %{
        db_name: "contents.season",
        db_values: ~w(winter spring summer fall)
      },
      "MediaSource" => %{
        db_name: "contents.source_material",
        db_values: ~w(original manga light_novel visual_novel video_game novel web_manga web_novel four_koma picture_book music mixed_media book card_game radio other unknown)
      },
      "MediaRelation" => %{
        db_name: "contents.content_relation",
        db_values: ~w(sequel prequel alternative_setting alternative_version side_story parent_story summary full_story spin_off adaptation character other)
      },
      "CharacterRole" => %{
        db_name: "contents.character_role",
        db_values: ~w(main supporting background)
      },
      "StaffLanguage" => %{
        db_name: "contents.voice_language",
        db_values: ~w(japanese english korean chinese spanish french german italian portuguese other)
      },
      "MediaListStatus" => %{
        db_name: "users.anime_list_status / users.manga_list_status",
        db_values: ~w(watching reading completed on_hold dropped plan_to_watch plan_to_read)
      },
      "UserTitleLanguage" => %{
        db_name: "users.title_language",
        db_values: ~w(english romaji native)
      }
    }

    data
    |> Enum.filter(fn {_key, value} -> value != nil end)
    |> Enum.sort_by(fn {key, _} -> key end)
    |> Enum.each(fn {enum_name, type_data} ->
      IO.puts("=" |> String.duplicate(70))
      IO.puts("#{enum_name}")
      IO.puts("=" |> String.duplicate(70))

      anilist_values = (type_data["enumValues"] || [])
                       |> Enum.map(& &1["name"])

      IO.puts("\nAniList values (#{length(anilist_values)}):")
      anilist_values
      |> Enum.each(fn val ->
        desc = Enum.find(type_data["enumValues"], & &1["name"] == val)["description"]
        desc_str = if desc && desc != "", do: " - #{desc}", else: ""
        IO.puts("  #{val}#{desc_str}")
      end)

      case Map.get(db_enums, enum_name) do
        nil ->
          IO.puts("\n[No direct DB equivalent mapped]")
        %{db_name: db_name, db_values: db_values} ->
          IO.puts("\nYour DB enum: #{db_name}")
          IO.puts("Your values: #{Enum.join(db_values, ", ")}")

          # Find differences
          anilist_lower = anilist_values |> Enum.map(&String.downcase/1) |> Enum.map(&String.replace(&1, "_", ""))
          db_lower = db_values |> Enum.map(&String.downcase/1) |> Enum.map(&String.replace(&1, "_", ""))

          missing_in_db = anilist_values
                          |> Enum.reject(fn v ->
                            normalized = v |> String.downcase() |> String.replace("_", "")
                            normalized in db_lower
                          end)

          extra_in_db = db_values
                        |> Enum.reject(fn v ->
                          normalized = v |> String.downcase() |> String.replace("_", "")
                          normalized in anilist_lower
                        end)

          if length(missing_in_db) > 0 do
            IO.puts("\n⚠️  AniList has but DB missing: #{Enum.join(missing_in_db, ", ")}")
          end

          if length(extra_in_db) > 0 do
            IO.puts("ℹ️  DB has extra (MAL/custom): #{Enum.join(extra_in_db, ", ")}")
          end

          if length(missing_in_db) == 0 && length(extra_in_db) == 0 do
            IO.puts("\n✅ Enums match!")
          end
      end

      IO.puts("")
    end)
  end

  defp fetch_media_full(media_type, id, id_type) do
    query_file = case media_type do
      :anime -> "lib/yunaos/anilist/queries/anime_full.graphql"
      :manga -> "lib/yunaos/anilist/queries/manga_full.graphql"
    end

    query = File.read!(query_file)

    variables = case id_type do
      :anilist -> %{"id" => id}
      :mal -> %{"idMal" => id}
    end

    IO.puts("\n=== Fetching #{media_type} (#{id_type} ID: #{id}) ===\n")

    body = Jason.encode!(%{"query" => query, "variables" => variables})

    case Req.post("https://graphql.anilist.co",
           body: body,
           headers: [{"content-type", "application/json"}],
           receive_timeout: 30_000
         ) do
      {:ok, %{status: 200, body: %{"data" => %{"Media" => media}}}} ->
        case media_type do
          :anime -> print_anime_summary(media)
          :manga -> print_manga_summary(media)
        end

        # Save full response to file
        output_file = "anilist_#{media_type}_#{id}.json"
        File.write!(output_file, Jason.encode!(media, pretty: true))
        IO.puts("\n[Full response saved to #{output_file}]")

      {:ok, %{status: 200, body: %{"data" => %{"Media" => nil}}}} ->
        IO.puts("No #{media_type} found with #{id_type} ID: #{id}")

      {:ok, %{status: status, body: body}} ->
        IO.puts("Error: HTTP #{status}")
        IO.inspect(body)

      {:error, reason} ->
        IO.puts("Error: #{inspect(reason)}")
    end
  end

  defp print_anime_summary(media) do
    IO.puts("=== #{media["title"]["romaji"]} ===")
    IO.puts("English: #{media["title"]["english"]}")
    IO.puts("Native: #{media["title"]["native"]}")
    IO.puts("")
    IO.puts("AniList ID: #{media["id"]}")
    IO.puts("MAL ID: #{media["idMal"]}")
    IO.puts("Format: #{media["format"]}")
    IO.puts("Status: #{media["status"]}")
    IO.puts("Episodes: #{media["episodes"]}")
    IO.puts("Duration: #{media["duration"]} min")
    IO.puts("Season: #{media["season"]} #{media["seasonYear"]}")
    IO.puts("Source: #{media["source"]}")
    IO.puts("")
    IO.puts("Score: #{media["averageScore"]}/100")
    IO.puts("Popularity: #{media["popularity"]}")
    IO.puts("Favourites: #{media["favourites"]}")
    IO.puts("")
    IO.puts("Genres: #{Enum.join(media["genres"] || [], ", ")}")
    IO.puts("")

    # Tags
    tags = media["tags"] || []
    IO.puts("Tags (#{length(tags)}):")
    tags
    |> Enum.take(10)
    |> Enum.each(fn tag ->
      spoiler = if tag["isMediaSpoiler"], do: " [SPOILER]", else: ""
      IO.puts("  - #{tag["name"]} (#{tag["rank"]}%)#{spoiler}")
    end)
    if length(tags) > 10, do: IO.puts("  ... and #{length(tags) - 10} more")
    IO.puts("")

    # Studios
    studios = get_in(media, ["studios", "edges"]) || []
    IO.puts("Studios (#{length(studios)}):")
    Enum.each(studios, fn edge ->
      main = if edge["isMain"], do: " [MAIN]", else: ""
      IO.puts("  - #{edge["node"]["name"]}#{main}")
    end)
    IO.puts("")

    # Characters & Voice Actors
    characters = get_in(media, ["characters", "edges"]) || []
    char_total = get_in(media, ["characters", "pageInfo", "total"]) || length(characters)
    IO.puts("Characters (#{length(characters)} fetched / #{char_total} total):")
    characters
    |> Enum.take(15)
    |> Enum.each(fn edge ->
      char = edge["node"]
      role = edge["role"]
      va_roles = edge["voiceActorRoles"] || []

      va_info = va_roles
      |> Enum.map(fn var ->
        va = var["voiceActor"]
        lang = va["language"] || "?"
        "#{va["name"]["full"]} (#{lang})"
      end)
      |> Enum.join(", ")

      va_str = if va_info != "", do: " -> #{va_info}", else: ""
      IO.puts("  [#{role}] #{char["name"]["full"]}#{va_str}")
    end)
    if length(characters) > 15, do: IO.puts("  ... and #{char_total - 15} more")
    IO.puts("")

    # Staff
    staff = get_in(media, ["staff", "edges"]) || []
    staff_total = get_in(media, ["staff", "pageInfo", "total"]) || length(staff)
    IO.puts("Staff (#{length(staff)} fetched / #{staff_total} total):")
    staff
    |> Enum.take(10)
    |> Enum.each(fn edge ->
      person = edge["node"]
      IO.puts("  [#{edge["role"]}] #{person["name"]["full"]}")
    end)
    if length(staff) > 10, do: IO.puts("  ... and #{staff_total - 10} more")
    IO.puts("")

    # Relations
    relations = get_in(media, ["relations", "edges"]) || []
    IO.puts("Relations (#{length(relations)}):")
    Enum.each(relations, fn edge ->
      node = edge["node"]
      IO.puts("  [#{edge["relationType"]}] #{node["title"]["romaji"]} (#{node["type"]}, MAL: #{node["idMal"]})")
    end)
    IO.puts("")

    # Streaming Episodes
    episodes = media["streamingEpisodes"] || []
    IO.puts("Streaming Episodes (#{length(episodes)}):")
    episodes
    |> Enum.take(5)
    |> Enum.each(fn ep ->
      IO.puts("  - #{ep["title"]} (#{ep["site"]})")
    end)
    if length(episodes) > 5, do: IO.puts("  ... and #{length(episodes) - 5} more")
    IO.puts("")

    # External Links
    links = media["externalLinks"] || []
    IO.puts("External Links (#{length(links)}):")
    Enum.each(links, fn link ->
      IO.puts("  - #{link["site"]}: #{link["url"]}")
    end)
    IO.puts("")

    # Stats
    IO.puts("Score Distribution:")
    (get_in(media, ["stats", "scoreDistribution"]) || [])
    |> Enum.each(fn dist ->
      bar = String.duplicate("█", div(dist["amount"], 1000))
      IO.puts("  #{dist["score"]}: #{bar} (#{dist["amount"]})")
    end)
  end

  defp print_manga_summary(media) do
    IO.puts("=== #{media["title"]["romaji"]} ===")
    IO.puts("English: #{media["title"]["english"]}")
    IO.puts("Native: #{media["title"]["native"]}")
    IO.puts("")
    IO.puts("AniList ID: #{media["id"]}")
    IO.puts("MAL ID: #{media["idMal"]}")
    IO.puts("Format: #{media["format"]}")
    IO.puts("Status: #{media["status"]}")
    IO.puts("Chapters: #{media["chapters"]}")
    IO.puts("Volumes: #{media["volumes"]}")
    IO.puts("Source: #{media["source"]}")
    IO.puts("Country: #{media["countryOfOrigin"]}")
    IO.puts("Licensed: #{media["isLicensed"]}")
    IO.puts("Adult: #{media["isAdult"]}")
    IO.puts("")
    IO.puts("Score: #{media["averageScore"]}/100 (mean: #{media["meanScore"]})")
    IO.puts("Popularity: #{media["popularity"]}")
    IO.puts("Favourites: #{media["favourites"]}")
    IO.puts("Trending: #{media["trending"]}")
    IO.puts("")
    IO.puts("Genres: #{Enum.join(media["genres"] || [], ", ")}")
    IO.puts("")

    # Tags
    tags = media["tags"] || []
    IO.puts("Tags (#{length(tags)}):")
    tags
    |> Enum.take(15)
    |> Enum.each(fn tag ->
      spoiler = if tag["isMediaSpoiler"], do: " [SPOILER]", else: ""
      adult = if tag["isAdult"], do: " [ADULT]", else: ""
      IO.puts("  - #{tag["name"]} (#{tag["rank"]}%) [#{tag["category"]}]#{spoiler}#{adult}")
    end)
    if length(tags) > 15, do: IO.puts("  ... and #{length(tags) - 15} more")
    IO.puts("")

    # Rankings
    rankings = media["rankings"] || []
    IO.puts("Rankings (#{length(rankings)}):")
    Enum.each(rankings, fn rank ->
      context = rank["context"] || "#{rank["type"]}"
      all_time = if rank["allTime"], do: " [ALL TIME]", else: ""
      IO.puts("  ##{rank["rank"]} - #{context}#{all_time}")
    end)
    IO.puts("")

    # Staff (Authors, Artists)
    staff = get_in(media, ["staff", "edges"]) || []
    staff_total = get_in(media, ["staff", "pageInfo", "total"]) || length(staff)
    IO.puts("Staff/Authors (#{length(staff)} fetched / #{staff_total} total):")
    staff
    |> Enum.take(10)
    |> Enum.each(fn edge ->
      person = edge["node"]
      occupations = Enum.join(person["primaryOccupations"] || [], ", ")
      years = case person["yearsActive"] do
        [start, stop] -> " (#{start}-#{stop})"
        [start] -> " (#{start}-present)"
        _ -> ""
      end
      IO.puts("  [#{edge["role"]}] #{person["name"]["full"]}#{years}")
      if occupations != "", do: IO.puts("    Occupations: #{occupations}")
    end)
    if length(staff) > 10, do: IO.puts("  ... and #{staff_total - 10} more")
    IO.puts("")

    # Characters
    characters = get_in(media, ["characters", "edges"]) || []
    char_total = get_in(media, ["characters", "pageInfo", "total"]) || length(characters)
    IO.puts("Characters (#{length(characters)} fetched / #{char_total} total):")
    characters
    |> Enum.take(10)
    |> Enum.each(fn edge ->
      char = edge["node"]
      role = edge["role"]
      age = if char["age"], do: ", Age: #{char["age"]}", else: ""
      gender = if char["gender"], do: ", #{char["gender"]}", else: ""
      IO.puts("  [#{role}] #{char["name"]["full"]}#{gender}#{age}")
    end)
    if length(characters) > 10, do: IO.puts("  ... and #{char_total - 10} more")
    IO.puts("")

    # Relations
    relations = get_in(media, ["relations", "edges"]) || []
    IO.puts("Relations (#{length(relations)}):")
    Enum.each(relations, fn edge ->
      node = edge["node"]
      IO.puts("  [#{edge["relationType"]}] #{node["title"]["romaji"]} (#{node["type"]}, #{node["format"]}, MAL: #{node["idMal"]})")
    end)
    IO.puts("")

    # Recommendations
    recommendations = get_in(media, ["recommendations", "edges"]) || []
    IO.puts("Recommendations (#{length(recommendations)}):")
    recommendations
    |> Enum.take(5)
    |> Enum.each(fn edge ->
      rec = edge["node"]["mediaRecommendation"]
      if rec do
        IO.puts("  - #{rec["title"]["romaji"]} (Score: #{rec["averageScore"]}, Rating: #{edge["node"]["rating"]})")
      end
    end)
    if length(recommendations) > 5, do: IO.puts("  ... and #{length(recommendations) - 5} more")
    IO.puts("")

    # External Links
    links = media["externalLinks"] || []
    IO.puts("External Links (#{length(links)}):")
    Enum.each(links, fn link ->
      type_str = if link["type"], do: " [#{link["type"]}]", else: ""
      IO.puts("  - #{link["site"]}#{type_str}: #{link["url"]}")
    end)
    IO.puts("")

    # Stats
    IO.puts("Score Distribution:")
    (get_in(media, ["stats", "scoreDistribution"]) || [])
    |> Enum.each(fn dist ->
      bar = String.duplicate("█", div(dist["amount"], 500))
      IO.puts("  #{dist["score"]}: #{bar} (#{dist["amount"]})")
    end)
    IO.puts("")

    IO.puts("Status Distribution:")
    (get_in(media, ["stats", "statusDistribution"]) || [])
    |> Enum.each(fn dist ->
      IO.puts("  #{dist["status"]}: #{dist["amount"]}")
    end)
  end
end
