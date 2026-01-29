defmodule Animetana.Anilist.Transformer do
  @moduledoc """
  Transforms AniList API responses to database-ready maps.

  Handles:
  - Enum value normalization (UPPERCASE -> lowercase)
  - Date parsing (year/month/day objects -> Date)
  - Nested data extraction (characters, staff, studios)
  - Field mapping (AniList names -> DB column names)
  """

  # ===========================================================================
  # ANIME
  # ===========================================================================

  def transform_anime(data) when is_map(data) do
    %{
      anilist_id: data["id"],
      mal_id: data["idMal"],

      # Titles
      title_en: data["title"]["english"],
      title_ja: data["title"]["native"],
      title_romaji: data["title"]["romaji"],
      title_synonyms: data["synonyms"] || [],

      # Description (only EN from AniList)
      synopsis_en: data["description"],
      synopsis_ja: nil,

      # Format & Status
      format: normalize_enum(data["format"]),
      status: normalize_enum(data["status"]),
      source: normalize_enum(data["source"]),

      # Season
      season: normalize_enum(data["season"]),
      season_year: data["seasonYear"],

      # Episodes & Duration
      episodes: data["episodes"],
      duration: data["duration"],

      # Dates
      start_date: parse_date(data["startDate"]),
      end_date: parse_date(data["endDate"]),

      # Next Airing
      next_airing_episode: get_in(data, ["nextAiringEpisode", "episode"]),
      next_airing_at: parse_timestamp(get_in(data, ["nextAiringEpisode", "airingAt"])),

      # Country & Flags
      country_of_origin: data["countryOfOrigin"],
      is_licensed: data["isLicensed"] || false,
      is_adult: data["isAdult"] || false,
      hashtag: data["hashtag"],

      # Images
      cover_image_extra_large: get_in(data, ["coverImage", "extraLarge"]),
      cover_image_large: get_in(data, ["coverImage", "large"]),
      cover_image_medium: get_in(data, ["coverImage", "medium"]),
      cover_image_color: get_in(data, ["coverImage", "color"]),
      banner_image: data["bannerImage"],

      # Trailer
      trailer_id: get_in(data, ["trailer", "id"]),
      trailer_site: get_in(data, ["trailer", "site"]),
      trailer_thumbnail: get_in(data, ["trailer", "thumbnail"]),

      # External Links (store as JSONB)
      external_links: transform_external_links(data["externalLinks"]),

      # URLs
      anilist_url: data["siteUrl"],

      # Timestamps
      last_synced_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
  end

  # ===========================================================================
  # MANGA
  # ===========================================================================

  def transform_manga(data) when is_map(data) do
    %{
      anilist_id: data["id"],
      mal_id: data["idMal"],

      # Titles
      title_en: data["title"]["english"],
      title_ja: data["title"]["native"],
      title_romaji: data["title"]["romaji"],
      title_synonyms: data["synonyms"] || [],

      # Description
      synopsis_en: data["description"],
      synopsis_ja: nil,

      # Format & Status
      format: normalize_enum(data["format"]),
      status: normalize_enum(data["status"]),
      source: normalize_enum(data["source"]),

      # Chapters & Volumes
      chapters: data["chapters"],
      volumes: data["volumes"],

      # Dates
      start_date: parse_date(data["startDate"]),
      end_date: parse_date(data["endDate"]),

      # Country & Flags
      country_of_origin: data["countryOfOrigin"],
      is_licensed: data["isLicensed"] || false,
      is_adult: data["isAdult"] || false,
      hashtag: data["hashtag"],

      # Images
      cover_image_extra_large: get_in(data, ["coverImage", "extraLarge"]),
      cover_image_large: get_in(data, ["coverImage", "large"]),
      cover_image_medium: get_in(data, ["coverImage", "medium"]),
      cover_image_color: get_in(data, ["coverImage", "color"]),
      banner_image: data["bannerImage"],

      # External Links
      external_links: transform_external_links(data["externalLinks"]),

      # URLs
      anilist_url: data["siteUrl"],

      # Timestamps
      last_synced_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
  end

  # ===========================================================================
  # TAGS (from AniList tags)
  # ===========================================================================

  @tag_categories %{
    "Cast-Main Cast" => "cast",
    "Cast-Traits" => "cast",
    "Setting-Universe" => "setting",
    "Setting-Place" => "setting",
    "Setting-Time" => "setting",
    "Setting-Scene" => "setting",
    "Theme-Action" => "theme",
    "Theme-Comedy" => "theme",
    "Theme-Drama" => "theme",
    "Theme-Fantasy" => "theme",
    "Theme-Game" => "theme",
    "Theme-Other" => "theme",
    "Theme-Romance" => "theme",
    "Theme-Sci-Fi" => "theme",
    "Theme-Slice of Life" => "theme",
    "Technical" => "technical",
    "Demographic" => "demographic",
    "Sexual Content" => "sexual_content"
  }

  def transform_tag(tag) when is_map(tag) do
    category = normalize_tag_category(tag["category"])

    %{
      anilist_id: tag["id"],
      name_en: tag["name"],
      name_ja: nil,
      name_romaji: nil,
      description_en: tag["description"],
      description_ja: nil,
      category: category,
      is_general_spoiler: tag["isGeneralSpoiler"] || false,
      is_adult: tag["isAdult"] || false
    }
  end

  # Extract tag rank and spoiler info for junction table
  def extract_tag_info(tag) when is_map(tag) do
    %{
      rank: tag["rank"],
      is_spoiler: tag["isMediaSpoiler"] || tag["isGeneralSpoiler"] || false
    }
  end

  defp normalize_tag_category(nil), do: "other"
  defp normalize_tag_category(category) do
    Map.get(@tag_categories, category, "other")
  end

  # ===========================================================================
  # STUDIOS
  # ===========================================================================

  def transform_studio(studio_data) when is_map(studio_data) do
    node = studio_data["node"] || studio_data

    %{
      anilist_id: node["id"],
      name_en: node["name"],
      name_ja: nil,
      name_romaji: nil,
      is_animation_studio: node["isAnimationStudio"] || false,
      anilist_url: node["siteUrl"],
      favorites_count: node["favourites"] || 0
    }
  end

  def extract_studio_role(edge) do
    if edge["isMain"], do: "main", else: "supporting"
  end

  # ===========================================================================
  # CHARACTERS
  # ===========================================================================

  def transform_character(char_data) when is_map(char_data) do
    node = char_data["node"] || char_data

    %{
      anilist_id: node["id"],
      name_en: get_in(node, ["name", "full"]),
      name_ja: get_in(node, ["name", "native"]),
      name_romaji: nil,
      name_alternatives: get_in(node, ["name", "alternative"]) || [],
      about_en: node["description"],
      about_ja: nil,
      gender: normalize_gender(node["gender"]),
      birth_date: parse_date(node["dateOfBirth"]),
      age: truncate(to_string_or_nil(node["age"]), 50), # characters.age is VARCHAR(50)
      blood_type: truncate(node["bloodType"], 5),
      image_large: get_in(node, ["image", "large"]),
      image_medium: get_in(node, ["image", "medium"]),
      anilist_url: node["siteUrl"],
      favorites_count: node["favourites"] || 0
    }
  end

  def extract_character_role(edge) do
    normalize_enum(edge["role"]) || "supporting"
  end

  # ===========================================================================
  # PEOPLE (Staff & Voice Actors)
  # ===========================================================================

  def transform_person(person_data) when is_map(person_data) do
    node = person_data["node"] || person_data

    %{
      anilist_id: node["id"],
      name_en: get_in(node, ["name", "full"]),
      name_ja: get_in(node, ["name", "native"]),
      name_romaji: nil,
      name_alternatives: get_in(node, ["name", "alternative"]) || [],
      about_en: node["description"],
      about_ja: nil,
      gender: normalize_gender(node["gender"]),
      birth_date: parse_date(node["dateOfBirth"]),
      death_date: parse_date(node["dateOfDeath"]),
      age: parse_age(node["age"]),
      blood_type: truncate(node["bloodType"], 5),
      hometown_en: node["homeTown"],
      hometown_ja: nil,
      language: normalize_language(node["languageV2"]),
      primary_occupations: node["primaryOccupations"] || [],
      years_active: node["yearsActive"] || [],
      image_large: get_in(node, ["image", "large"]),
      image_medium: get_in(node, ["image", "medium"]),
      anilist_url: node["siteUrl"],
      favorites_count: node["favourites"] || 0
    }
  end

  # ===========================================================================
  # VOICE ACTOR ROLES
  # ===========================================================================

  def extract_voice_actor_roles(character_edge) do
    (character_edge["voiceActorRoles"] || [])
    |> Enum.map(fn var ->
      %{
        voice_actor: transform_person(var["voiceActor"]),
        language: normalize_language(get_in(var, ["voiceActor", "languageV2"])),
        role_notes: var["roleNotes"],
        dub_group: var["dubGroup"]
      }
    end)
  end

  # ===========================================================================
  # RELATIONS
  # ===========================================================================

  def transform_relation(edge) when is_map(edge) do
    node = edge["node"]

    %{
      relation_type: normalize_enum(edge["relationType"]),
      target_anilist_id: node["id"],
      target_mal_id: node["idMal"],
      target_type: normalize_enum(node["type"]), # ANIME or MANGA
      target_format: normalize_enum(node["format"]),
      target_title: get_in(node, ["title", "romaji"])
    }
  end

  # ===========================================================================
  # RECOMMENDATIONS
  # ===========================================================================

  def transform_recommendation(edge) when is_map(edge) do
    rec = edge["node"]
    media = rec["mediaRecommendation"]

    if media do
      %{
        rating: rec["rating"] || 0,
        recommended_anilist_id: media["id"],
        recommended_mal_id: media["idMal"],
        recommended_type: normalize_enum(media["type"]),
        recommended_title: get_in(media, ["title", "romaji"])
      }
    else
      nil
    end
  end

  # ===========================================================================
  # RANKINGS
  # ===========================================================================

  def transform_ranking(ranking) when is_map(ranking) do
    %{
      rank: ranking["rank"],
      type: normalize_enum(ranking["type"]),
      format: normalize_enum(ranking["format"]),
      year: ranking["year"],
      season: normalize_enum(ranking["season"]),
      all_time: ranking["allTime"] || false,
      context: ranking["context"]
    }
  end

  # ===========================================================================
  # SCORE DISTRIBUTION
  # ===========================================================================

  def transform_score_distribution(dist) when is_map(dist) do
    # AniList uses 10-100 scale, we use 1-10
    score = div(dist["score"], 10)

    %{
      score: score,
      count: dist["amount"] || 0
    }
  end

  # ===========================================================================
  # STATUS DISTRIBUTION
  # ===========================================================================

  def transform_status_distribution(dist) when is_map(dist) do
    %{
      status: normalize_enum(dist["status"]),
      count: dist["amount"] || 0
    }
  end

  # ===========================================================================
  # HELPERS
  # ===========================================================================

  defp normalize_enum(nil), do: nil
  defp normalize_enum(value) when is_binary(value) do
    value |> String.downcase()
  end

  defp normalize_gender(nil), do: "unknown"
  defp normalize_gender("Male"), do: "male"
  defp normalize_gender("Female"), do: "female"
  defp normalize_gender("Non-binary"), do: "non_binary"
  defp normalize_gender(_), do: "unknown"

  @valid_languages ~w(japanese english korean chinese spanish portuguese french german italian hebrew hungarian arabic filipino catalan finnish turkish dutch swedish thai tagalog malaysian indonesian vietnamese nepali hindi urdu other)

  defp normalize_language(nil), do: "other"
  defp normalize_language(lang) when is_binary(lang) do
    normalized = lang |> String.downcase()
    if normalized in @valid_languages, do: normalized, else: "other"
  end

  defp truncate(nil, _max), do: nil
  defp truncate(str, max) when is_binary(str) and byte_size(str) > max do
    String.slice(str, 0, max - 3) <> "..."
  end
  defp truncate(str, _max), do: str

  defp to_string_or_nil(nil), do: nil
  defp to_string_or_nil(val) when is_binary(val), do: val
  defp to_string_or_nil(val), do: to_string(val)

  # Parse age - AniList returns either integer or string like "9 (1st & 2nd), 20 (StrikerS)"
  # We extract the first number
  defp parse_age(nil), do: nil
  defp parse_age(age) when is_integer(age), do: age
  defp parse_age(age) when is_binary(age) do
    case Integer.parse(age) do
      {num, _} -> num
      :error -> nil
    end
  end
  defp parse_age(_), do: nil

  defp parse_date(nil), do: nil
  defp parse_date(%{"year" => nil}), do: nil
  defp parse_date(%{"year" => year, "month" => month, "day" => day}) do
    month = month || 1
    day = day || 1

    case Date.new(year, month, day) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_timestamp(nil), do: nil
  defp parse_timestamp(unix_timestamp) when is_integer(unix_timestamp) do
    DateTime.from_unix!(unix_timestamp) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
  end

  defp transform_external_links(nil), do: []
  defp transform_external_links(links) when is_list(links) do
    Enum.map(links, fn link ->
      %{
        "url" => link["url"],
        "site" => link["site"],
        "type" => link["type"],
        "language" => link["language"]
      }
    end)
  end
end
