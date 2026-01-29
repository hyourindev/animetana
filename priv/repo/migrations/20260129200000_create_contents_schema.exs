defmodule Animetana.Repo.Migrations.CreateContentsSchema do
  @moduledoc """
  Creates the contents schema for Animetana.

  This schema contains ALL content data:
  - Anime, Manga, Episodes, Chapters
  - People, Characters, Studios
  - Genres, Tags, Themes, Demographics
  - All relationship/junction tables
  - Rankings, Recommendations, Airing Schedule
  - Score distributions, Status distributions

  NO user-generated content (reviews, votes, lists) - those go in separate schemas.

  Naming conventions:
  - Titles/Names: _en, _ja, _romaji (3 versions)
  - Descriptions/Synopses/About: _en, _ja (2 versions only)
  - External IDs: mal_id, anilist_id, kitsu_id (for cross-referencing only, no external scores)
  - Scores: Animetana_*_en, Animetana_*_ja (separate English and Japanese community scores)
  """

  use Ecto.Migration

  def change do
    # ============================================================================
    # SCHEMA & EXTENSIONS
    # ============================================================================
    execute "CREATE SCHEMA IF NOT EXISTS contents", "DROP SCHEMA IF EXISTS contents CASCADE"
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm", "DROP EXTENSION IF EXISTS pg_trgm"
    execute "CREATE EXTENSION IF NOT EXISTS btree_gin", "DROP EXTENSION IF EXISTS btree_gin"

    # ============================================================================
    # ENUM TYPES
    # ============================================================================
    create_enum_types()

    # ============================================================================
    # CORE CONTENT TABLES
    # ============================================================================
    create_anime_table()
    create_manga_table()
    create_episodes_table()
    create_chapters_table()

    # ============================================================================
    # PEOPLE & CHARACTERS
    # ============================================================================
    create_people_table()
    create_characters_table()
    create_studios_table()

    # ============================================================================
    # TAXONOMY (Tags, Demographics)
    # ============================================================================
    create_tags_table()
    create_demographics_table()

    # ============================================================================
    # RELATIONSHIP/JUNCTION TABLES
    # ============================================================================
    create_anime_relationship_tables()
    create_manga_relationship_tables()
    create_content_relations_table()

    # ============================================================================
    # AIRING SCHEDULE
    # ============================================================================
    create_airing_schedule_table()

    # ============================================================================
    # INDEXES
    # ============================================================================
    create_indexes()

    # ============================================================================
    # FUNCTIONS & TRIGGERS
    # ============================================================================
    create_functions()
    create_triggers()
  end

  # ============================================================================
  # ENUM TYPES
  # ============================================================================
  defp create_enum_types do
    # Anime format (from AniList MediaFormat)
    execute """
    CREATE TYPE contents.anime_format AS ENUM (
      'tv', 'tv_short', 'movie', 'special', 'ova', 'ona', 'music', 'cm', 'pv', 'unknown'
    )
    """, "DROP TYPE IF EXISTS contents.anime_format"

    # Anime status (from AniList MediaStatus)
    execute """
    CREATE TYPE contents.anime_status AS ENUM (
      'releasing', 'finished', 'not_yet_released', 'cancelled', 'hiatus', 'unknown'
    )
    """, "DROP TYPE IF EXISTS contents.anime_status"

    # Manga format
    execute """
    CREATE TYPE contents.manga_format AS ENUM (
      'manga', 'novel', 'one_shot', 'doujinshi', 'manhwa', 'manhua', 'unknown'
    )
    """, "DROP TYPE IF EXISTS contents.manga_format"

    # Manga status
    execute """
    CREATE TYPE contents.manga_status AS ENUM (
      'releasing', 'finished', 'not_yet_released', 'cancelled', 'hiatus', 'unknown'
    )
    """, "DROP TYPE IF EXISTS contents.manga_status"

    # Season
    execute """
    CREATE TYPE contents.season AS ENUM ('winter', 'spring', 'summer', 'fall')
    """, "DROP TYPE IF EXISTS contents.season"

    # Source material (from AniList MediaSource)
    execute """
    CREATE TYPE contents.source_material AS ENUM (
      'original', 'manga', 'light_novel', 'visual_novel', 'video_game', 'novel',
      'doujinshi', 'anime', 'web_novel', 'live_action', 'game', 'comic',
      'multimedia_project', 'picture_book', 'other', 'unknown'
    )
    """, "DROP TYPE IF EXISTS contents.source_material"

    # Content relation types (from AniList MediaRelation)
    execute """
    CREATE TYPE contents.relation_type AS ENUM (
      'adaptation', 'prequel', 'sequel', 'parent', 'side_story', 'character',
      'summary', 'alternative', 'spin_off', 'other', 'source', 'compilation', 'contains'
    )
    """, "DROP TYPE IF EXISTS contents.relation_type"

    # Character role
    execute """
    CREATE TYPE contents.character_role AS ENUM ('main', 'supporting', 'background')
    """, "DROP TYPE IF EXISTS contents.character_role"

    # Staff/voice actor language
    execute """
    CREATE TYPE contents.staff_language AS ENUM (
      'japanese', 'english', 'korean', 'chinese', 'spanish', 'portuguese',
      'french', 'german', 'italian', 'hebrew', 'hungarian', 'arabic',
      'filipino', 'catalan', 'finnish', 'turkish', 'dutch', 'swedish',
      'thai', 'tagalog', 'malaysian', 'indonesian', 'vietnamese',
      'nepali', 'hindi', 'urdu', 'other'
    )
    """, "DROP TYPE IF EXISTS contents.staff_language"

    # Studio role
    execute """
    CREATE TYPE contents.studio_role AS ENUM ('main', 'supporting')
    """, "DROP TYPE IF EXISTS contents.studio_role"

    # External link type (from AniList ExternalLinkType)
    execute """
    CREATE TYPE contents.external_link_type AS ENUM ('streaming', 'social', 'info')
    """, "DROP TYPE IF EXISTS contents.external_link_type"

    # Tag category
    execute """
    CREATE TYPE contents.tag_category AS ENUM (
      'theme', 'setting', 'cast', 'demographic', 'technical', 'sexual_content', 'other'
    )
    """, "DROP TYPE IF EXISTS contents.tag_category"

    # Gender
    execute """
    CREATE TYPE contents.gender AS ENUM ('male', 'female', 'non_binary', 'unknown')
    """, "DROP TYPE IF EXISTS contents.gender"

  end

  # ============================================================================
  # ANIME TABLE
  # ============================================================================
  defp create_anime_table do
    execute """
    CREATE TABLE contents.anime (
      id BIGSERIAL PRIMARY KEY,

      -- External IDs (for cross-referencing only)
      mal_id INTEGER,
      anilist_id INTEGER,
      kitsu_id INTEGER,

      -- Titles (trilingual)
      title_en VARCHAR(500),
      title_ja VARCHAR(500),
      title_romaji VARCHAR(500),
      title_synonyms TEXT[] DEFAULT ARRAY[]::TEXT[],

      -- Descriptions (bilingual)
      synopsis_en TEXT,
      synopsis_ja TEXT,
      synopsis_html TEXT,
      background_en TEXT,
      background_ja TEXT,

      -- Format & Status
      format contents.anime_format DEFAULT 'unknown',
      status contents.anime_status DEFAULT 'unknown',
      source contents.source_material,

      -- Season & Timing
      season contents.season,
      season_year INTEGER CHECK (season_year IS NULL OR (season_year >= 1900 AND season_year <= 2100)),
      broadcast_day VARCHAR(20),
      broadcast_time TIME(0),

      -- Episodes & Duration
      episodes INTEGER CHECK (episodes IS NULL OR episodes >= 0),
      duration INTEGER CHECK (duration IS NULL OR duration >= 0),

      -- Dates
      start_date DATE,
      end_date DATE,

      -- Next Airing (for currently airing anime)
      next_airing_episode INTEGER CHECK (next_airing_episode IS NULL OR next_airing_episode > 0),
      next_airing_at TIMESTAMP(0),

      -- Country & Licensing
      country_of_origin VARCHAR(2) DEFAULT 'JP',
      is_licensed BOOLEAN DEFAULT TRUE,
      is_adult BOOLEAN DEFAULT FALSE,
      hashtag VARCHAR(100),

      -- Images
      cover_image_extra_large VARCHAR(1000),
      cover_image_large VARCHAR(1000),
      cover_image_medium VARCHAR(1000),
      cover_image_color VARCHAR(10),
      banner_image VARCHAR(1000),

      -- Trailer
      trailer_id VARCHAR(100),
      trailer_site VARCHAR(50),
      trailer_thumbnail VARCHAR(1000),

      -- External Links & Streaming (stored as JSONB for flexibility)
      external_links JSONB DEFAULT '[]'::JSONB,
      streaming_links JSONB DEFAULT '[]'::JSONB,

      -- Site URLs
      anilist_url VARCHAR(500),
      mal_url VARCHAR(500),

      -- Animetana Scores - English community
      Animetana_score_en NUMERIC(4,2) DEFAULT 0.0 CHECK (Animetana_score_en >= 0 AND Animetana_score_en <= 10),
      Animetana_scored_by_en INTEGER DEFAULT 0 CHECK (Animetana_scored_by_en >= 0),
      Animetana_rank_en INTEGER CHECK (Animetana_rank_en IS NULL OR Animetana_rank_en > 0),
      Animetana_popularity_en INTEGER CHECK (Animetana_popularity_en IS NULL OR Animetana_popularity_en > 0),
      Animetana_favorites_en INTEGER DEFAULT 0 CHECK (Animetana_favorites_en >= 0),
      Animetana_trending_en INTEGER DEFAULT 0 CHECK (Animetana_trending_en >= 0),

      -- Animetana Scores - Japanese community
      Animetana_score_ja NUMERIC(4,2) DEFAULT 0.0 CHECK (Animetana_score_ja >= 0 AND Animetana_score_ja <= 10),
      Animetana_scored_by_ja INTEGER DEFAULT 0 CHECK (Animetana_scored_by_ja >= 0),
      Animetana_rank_ja INTEGER CHECK (Animetana_rank_ja IS NULL OR Animetana_rank_ja > 0),
      Animetana_popularity_ja INTEGER CHECK (Animetana_popularity_ja IS NULL OR Animetana_popularity_ja > 0),
      Animetana_favorites_ja INTEGER DEFAULT 0 CHECK (Animetana_favorites_ja >= 0),
      Animetana_trending_ja INTEGER DEFAULT 0 CHECK (Animetana_trending_ja >= 0),

      -- Aggregated Stats
      average_rating NUMERIC(4,2) DEFAULT 0.0 CHECK (average_rating >= 0 AND average_rating <= 10),
      rating_count INTEGER DEFAULT 0 CHECK (rating_count >= 0),
      members_count INTEGER DEFAULT 0 CHECK (members_count >= 0),
      favorites_count INTEGER DEFAULT 0 CHECK (favorites_count >= 0),

      -- Algorithm Scores
      quality_score NUMERIC(5,2) DEFAULT 0.0 CHECK (quality_score >= 0),
      engagement_score NUMERIC(5,2) DEFAULT 0.0 CHECK (engagement_score >= 0),
      trending_score NUMERIC(5,2) DEFAULT 0.0 CHECK (trending_score >= 0),

      -- Full-text Search
      search_vector TSVECTOR,

      -- Metadata
      last_synced_at TIMESTAMP(0),
      deleted_at TIMESTAMP(0),
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),

      -- Constraints
      CONSTRAINT anime_season_check CHECK (
        (season IS NULL AND season_year IS NULL) OR
        (season IS NOT NULL AND season_year IS NOT NULL)
      )
    )
    """, "DROP TABLE IF EXISTS contents.anime CASCADE"
  end

  # ============================================================================
  # MANGA TABLE
  # ============================================================================
  defp create_manga_table do
    execute """
    CREATE TABLE contents.manga (
      id BIGSERIAL PRIMARY KEY,

      -- External IDs
      mal_id INTEGER,
      anilist_id INTEGER,
      kitsu_id INTEGER,

      -- Titles (trilingual)
      title_en VARCHAR(500),
      title_ja VARCHAR(500),
      title_romaji VARCHAR(500),
      title_synonyms TEXT[] DEFAULT ARRAY[]::TEXT[],

      -- Descriptions (bilingual)
      synopsis_en TEXT,
      synopsis_ja TEXT,
      synopsis_html TEXT,
      background_en TEXT,
      background_ja TEXT,

      -- Format & Status
      format contents.manga_format DEFAULT 'unknown',
      status contents.manga_status DEFAULT 'unknown',
      source contents.source_material,

      -- Chapters & Volumes
      chapters INTEGER CHECK (chapters IS NULL OR chapters >= 0),
      volumes INTEGER CHECK (volumes IS NULL OR volumes >= 0),

      -- Dates
      start_date DATE,
      end_date DATE,

      -- Country & Licensing
      country_of_origin VARCHAR(2) DEFAULT 'JP',
      is_licensed BOOLEAN DEFAULT TRUE,
      is_adult BOOLEAN DEFAULT FALSE,
      hashtag VARCHAR(100),

      -- Images
      cover_image_extra_large VARCHAR(1000),
      cover_image_large VARCHAR(1000),
      cover_image_medium VARCHAR(1000),
      cover_image_color VARCHAR(10),
      banner_image VARCHAR(1000),

      -- External Links
      external_links JSONB DEFAULT '[]'::JSONB,

      -- Site URLs
      anilist_url VARCHAR(500),
      mal_url VARCHAR(500),

      -- Animetana Scores - English community
      Animetana_score_en NUMERIC(4,2) DEFAULT 0.0 CHECK (Animetana_score_en >= 0 AND Animetana_score_en <= 10),
      Animetana_scored_by_en INTEGER DEFAULT 0 CHECK (Animetana_scored_by_en >= 0),
      Animetana_rank_en INTEGER CHECK (Animetana_rank_en IS NULL OR Animetana_rank_en > 0),
      Animetana_popularity_en INTEGER CHECK (Animetana_popularity_en IS NULL OR Animetana_popularity_en > 0),
      Animetana_favorites_en INTEGER DEFAULT 0 CHECK (Animetana_favorites_en >= 0),
      Animetana_trending_en INTEGER DEFAULT 0 CHECK (Animetana_trending_en >= 0),

      -- Animetana Scores - Japanese community
      Animetana_score_ja NUMERIC(4,2) DEFAULT 0.0 CHECK (Animetana_score_ja >= 0 AND Animetana_score_ja <= 10),
      Animetana_scored_by_ja INTEGER DEFAULT 0 CHECK (Animetana_scored_by_ja >= 0),
      Animetana_rank_ja INTEGER CHECK (Animetana_rank_ja IS NULL OR Animetana_rank_ja > 0),
      Animetana_popularity_ja INTEGER CHECK (Animetana_popularity_ja IS NULL OR Animetana_popularity_ja > 0),
      Animetana_favorites_ja INTEGER DEFAULT 0 CHECK (Animetana_favorites_ja >= 0),
      Animetana_trending_ja INTEGER DEFAULT 0 CHECK (Animetana_trending_ja >= 0),

      -- Aggregated Stats
      average_rating NUMERIC(4,2) DEFAULT 0.0 CHECK (average_rating >= 0 AND average_rating <= 10),
      rating_count INTEGER DEFAULT 0 CHECK (rating_count >= 0),
      members_count INTEGER DEFAULT 0 CHECK (members_count >= 0),
      favorites_count INTEGER DEFAULT 0 CHECK (favorites_count >= 0),

      -- Algorithm Scores
      quality_score NUMERIC(5,2) DEFAULT 0.0 CHECK (quality_score >= 0),
      engagement_score NUMERIC(5,2) DEFAULT 0.0 CHECK (engagement_score >= 0),
      trending_score NUMERIC(5,2) DEFAULT 0.0 CHECK (trending_score >= 0),

      -- Full-text Search
      search_vector TSVECTOR,

      -- Metadata
      last_synced_at TIMESTAMP(0),
      deleted_at TIMESTAMP(0),
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.manga CASCADE"
  end

  # ============================================================================
  # EPISODES TABLE
  # ============================================================================
  defp create_episodes_table do
    execute """
    CREATE TABLE contents.episodes (
      id BIGSERIAL PRIMARY KEY,
      anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,

      -- External IDs
      mal_id INTEGER,
      anilist_id INTEGER,

      -- Episode Info
      episode_number INTEGER NOT NULL CHECK (episode_number > 0),

      -- Titles (trilingual)
      title_en VARCHAR(500),
      title_ja VARCHAR(500),
      title_romaji VARCHAR(500),

      -- Description (bilingual)
      synopsis_en TEXT,
      synopsis_ja TEXT,

      -- Media
      thumbnail_url VARCHAR(1000),
      duration INTEGER CHECK (duration IS NULL OR duration >= 0),

      -- Airing
      aired_at TIMESTAMP(0),

      -- Flags
      is_filler BOOLEAN DEFAULT FALSE,
      is_recap BOOLEAN DEFAULT FALSE,

      -- Animetana Scores - English community
      Animetana_score_en NUMERIC(4,2) DEFAULT 0.0 CHECK (Animetana_score_en >= 0 AND Animetana_score_en <= 10),
      Animetana_scored_by_en INTEGER DEFAULT 0 CHECK (Animetana_scored_by_en >= 0),
      Animetana_rank_en INTEGER,
      Animetana_popularity_en INTEGER,

      -- Animetana Scores - Japanese community
      Animetana_score_ja NUMERIC(4,2) DEFAULT 0.0 CHECK (Animetana_score_ja >= 0 AND Animetana_score_ja <= 10),
      Animetana_scored_by_ja INTEGER DEFAULT 0 CHECK (Animetana_scored_by_ja >= 0),
      Animetana_rank_ja INTEGER,
      Animetana_popularity_ja INTEGER,

      -- Engagement
      view_count BIGINT DEFAULT 0 CHECK (view_count >= 0),
      favorites_count INTEGER DEFAULT 0 CHECK (favorites_count >= 0),
      comment_count INTEGER DEFAULT 0 CHECK (comment_count >= 0),

      -- Aggregated Stats
      average_rating NUMERIC(4,2) DEFAULT 0.0 CHECK (average_rating >= 0 AND average_rating <= 10),
      rating_count INTEGER DEFAULT 0 CHECK (rating_count >= 0),

      -- Metadata
      deleted_at TIMESTAMP(0),
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),

      UNIQUE (anime_id, episode_number)
    )
    """, "DROP TABLE IF EXISTS contents.episodes CASCADE"
  end

  # ============================================================================
  # CHAPTERS TABLE
  # ============================================================================
  defp create_chapters_table do
    execute """
    CREATE TABLE contents.chapters (
      id BIGSERIAL PRIMARY KEY,
      manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,

      -- External IDs
      mal_id INTEGER,
      anilist_id INTEGER,

      -- Chapter Info
      chapter_number NUMERIC(10,2) NOT NULL CHECK (chapter_number > 0),
      volume_number INTEGER CHECK (volume_number IS NULL OR volume_number > 0),

      -- Titles (trilingual)
      title_en VARCHAR(500),
      title_ja VARCHAR(500),
      title_romaji VARCHAR(500),

      -- Description (bilingual)
      synopsis_en TEXT,
      synopsis_ja TEXT,

      -- Media
      page_count INTEGER CHECK (page_count IS NULL OR page_count >= 0),

      -- Published
      published_at DATE,

      -- Animetana Scores - English community
      Animetana_score_en NUMERIC(4,2) DEFAULT 0.0 CHECK (Animetana_score_en >= 0 AND Animetana_score_en <= 10),
      Animetana_scored_by_en INTEGER DEFAULT 0 CHECK (Animetana_scored_by_en >= 0),
      Animetana_rank_en INTEGER,
      Animetana_popularity_en INTEGER,

      -- Animetana Scores - Japanese community
      Animetana_score_ja NUMERIC(4,2) DEFAULT 0.0 CHECK (Animetana_score_ja >= 0 AND Animetana_score_ja <= 10),
      Animetana_scored_by_ja INTEGER DEFAULT 0 CHECK (Animetana_scored_by_ja >= 0),
      Animetana_rank_ja INTEGER,
      Animetana_popularity_ja INTEGER,

      -- Engagement
      view_count BIGINT DEFAULT 0 CHECK (view_count >= 0),
      favorites_count INTEGER DEFAULT 0 CHECK (favorites_count >= 0),
      comment_count INTEGER DEFAULT 0 CHECK (comment_count >= 0),

      -- Aggregated Stats
      average_rating NUMERIC(4,2) DEFAULT 0.0 CHECK (average_rating >= 0 AND average_rating <= 10),
      rating_count INTEGER DEFAULT 0 CHECK (rating_count >= 0),

      -- Metadata
      deleted_at TIMESTAMP(0),
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),

      UNIQUE (manga_id, chapter_number)
    )
    """, "DROP TABLE IF EXISTS contents.chapters CASCADE"
  end

  # ============================================================================
  # PEOPLE TABLE (Staff, Voice Actors, Authors, Artists)
  # ============================================================================
  defp create_people_table do
    execute """
    CREATE TABLE contents.people (
      id BIGSERIAL PRIMARY KEY,

      -- External IDs
      mal_id INTEGER,
      anilist_id INTEGER,

      -- Names (trilingual)
      name_en VARCHAR(300),
      name_ja VARCHAR(300),
      name_romaji VARCHAR(300),
      name_alternatives TEXT[] DEFAULT ARRAY[]::TEXT[],

      -- About (bilingual)
      about_en TEXT,
      about_ja TEXT,

      -- Personal Info
      gender contents.gender DEFAULT 'unknown',
      birth_date DATE,
      death_date DATE,
      age INTEGER CHECK (age IS NULL OR age >= 0),
      blood_type VARCHAR(5),
      hometown_en VARCHAR(200),
      hometown_ja VARCHAR(200),

      -- Professional Info
      language contents.staff_language,
      primary_occupations TEXT[] DEFAULT ARRAY[]::TEXT[],
      years_active INTEGER[] DEFAULT ARRAY[]::INTEGER[],

      -- Images
      image_large VARCHAR(1000),
      image_medium VARCHAR(1000),

      -- Site URLs
      anilist_url VARCHAR(500),
      mal_url VARCHAR(500),

      -- Stats
      favorites_count INTEGER DEFAULT 0 CHECK (favorites_count >= 0),

      -- Metadata
      deleted_at TIMESTAMP(0),
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.people CASCADE"
  end

  # ============================================================================
  # CHARACTERS TABLE
  # ============================================================================
  defp create_characters_table do
    execute """
    CREATE TABLE contents.characters (
      id BIGSERIAL PRIMARY KEY,

      -- External IDs
      mal_id INTEGER,
      anilist_id INTEGER,

      -- Names (trilingual)
      name_en VARCHAR(300),
      name_ja VARCHAR(300),
      name_romaji VARCHAR(300),
      name_alternatives TEXT[] DEFAULT ARRAY[]::TEXT[],
      name_spoilers TEXT[] DEFAULT ARRAY[]::TEXT[],

      -- About (bilingual)
      about_en TEXT,
      about_ja TEXT,

      -- Personal Info
      gender contents.gender DEFAULT 'unknown',
      birth_date DATE,
      age VARCHAR(50),
      blood_type VARCHAR(5),

      -- Images
      image_large VARCHAR(1000),
      image_medium VARCHAR(1000),

      -- Site URLs
      anilist_url VARCHAR(500),
      mal_url VARCHAR(500),

      -- Stats
      favorites_count INTEGER DEFAULT 0 CHECK (favorites_count >= 0),

      -- Metadata
      deleted_at TIMESTAMP(0),
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.characters CASCADE"
  end

  # ============================================================================
  # STUDIOS TABLE
  # ============================================================================
  defp create_studios_table do
    execute """
    CREATE TABLE contents.studios (
      id BIGSERIAL PRIMARY KEY,

      -- External IDs
      mal_id INTEGER,
      anilist_id INTEGER,

      -- Names (trilingual)
      name_en VARCHAR(300) NOT NULL,
      name_ja VARCHAR(300),
      name_romaji VARCHAR(300),

      -- About (bilingual)
      about_en TEXT,
      about_ja TEXT,

      -- Info
      is_animation_studio BOOLEAN DEFAULT TRUE,
      established_date DATE,

      -- Images
      logo_url VARCHAR(1000),

      -- Site URLs
      anilist_url VARCHAR(500),
      mal_url VARCHAR(500),
      website_url VARCHAR(500),

      -- Stats
      favorites_count INTEGER DEFAULT 0 CHECK (favorites_count >= 0),
      anime_count INTEGER DEFAULT 0 CHECK (anime_count >= 0),

      -- Metadata
      deleted_at TIMESTAMP(0),
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.studios CASCADE"
  end

  # ============================================================================
  # TAGS TABLE (AniList tags - replaces genres)
  # ============================================================================
  defp create_tags_table do
    execute """
    CREATE TABLE contents.tags (
      id BIGSERIAL PRIMARY KEY,

      -- External IDs
      anilist_id INTEGER NOT NULL,

      -- Names (trilingual)
      name_en VARCHAR(100) NOT NULL,
      name_ja VARCHAR(100),
      name_romaji VARCHAR(100),

      -- Description (bilingual)
      description_en TEXT,
      description_ja TEXT,

      -- Category
      category contents.tag_category DEFAULT 'other',

      -- Flags
      is_general_spoiler BOOLEAN DEFAULT FALSE,
      is_adult BOOLEAN DEFAULT FALSE,

      -- Metadata
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.tags CASCADE"
  end


  # ============================================================================
  # DEMOGRAPHICS TABLE
  # ============================================================================
  defp create_demographics_table do
    execute """
    CREATE TABLE contents.demographics (
      id BIGSERIAL PRIMARY KEY,

      -- External IDs
      mal_id INTEGER,
      anilist_id INTEGER,

      -- Names (trilingual)
      name_en VARCHAR(100) NOT NULL,
      name_ja VARCHAR(100),
      name_romaji VARCHAR(100),

      -- Description (bilingual)
      description_en TEXT,
      description_ja TEXT,

      -- Metadata
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.demographics CASCADE"
  end


  # ============================================================================
  # ANIME RELATIONSHIP TABLES
  # ============================================================================
  defp create_anime_relationship_tables do
    # Anime <-> Genres
    # Anime <-> Tags (with rank and spoiler info)
    execute """
    CREATE TABLE contents.anime_tags (
      anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
      tag_id BIGINT NOT NULL REFERENCES contents.tags(id) ON DELETE CASCADE,
      rank INTEGER CHECK (rank IS NULL OR (rank >= 0 AND rank <= 100)),
      is_spoiler BOOLEAN DEFAULT FALSE,
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      PRIMARY KEY (anime_id, tag_id)
    )
    """, "DROP TABLE IF EXISTS contents.anime_tags CASCADE"

    # Anime <-> Demographics
    execute """
    CREATE TABLE contents.anime_demographics (
      anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
      demographic_id BIGINT NOT NULL REFERENCES contents.demographics(id) ON DELETE CASCADE,
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      PRIMARY KEY (anime_id, demographic_id)
    )
    """, "DROP TABLE IF EXISTS contents.anime_demographics CASCADE"

    # Anime <-> Studios
    execute """
    CREATE TABLE contents.anime_studios (
      anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
      studio_id BIGINT NOT NULL REFERENCES contents.studios(id) ON DELETE CASCADE,
      role contents.studio_role DEFAULT 'supporting',
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      PRIMARY KEY (anime_id, studio_id)
    )
    """, "DROP TABLE IF EXISTS contents.anime_studios CASCADE"

    # Anime <-> Characters
    execute """
    CREATE TABLE contents.anime_characters (
      anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
      character_id BIGINT NOT NULL REFERENCES contents.characters(id) ON DELETE CASCADE,
      role contents.character_role DEFAULT 'supporting',
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      PRIMARY KEY (anime_id, character_id)
    )
    """, "DROP TABLE IF EXISTS contents.anime_characters CASCADE"

    # Anime <-> Staff
    execute """
    CREATE TABLE contents.anime_staff (
      id BIGSERIAL PRIMARY KEY,
      anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
      person_id BIGINT NOT NULL REFERENCES contents.people(id) ON DELETE CASCADE,
      role VARCHAR(200) NOT NULL,
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      UNIQUE (anime_id, person_id, role)
    )
    """, "DROP TABLE IF EXISTS contents.anime_staff CASCADE"

    # Character Voice Actors
    execute """
    CREATE TABLE contents.character_voice_actors (
      id BIGSERIAL PRIMARY KEY,
      anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
      character_id BIGINT NOT NULL REFERENCES contents.characters(id) ON DELETE CASCADE,
      person_id BIGINT NOT NULL REFERENCES contents.people(id) ON DELETE CASCADE,
      language contents.staff_language DEFAULT 'japanese',
      role_notes TEXT,
      dub_group VARCHAR(100),
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      UNIQUE (anime_id, character_id, person_id, language)
    )
    """, "DROP TABLE IF EXISTS contents.character_voice_actors CASCADE"
  end

  # ============================================================================
  # MANGA RELATIONSHIP TABLES
  # ============================================================================
  defp create_manga_relationship_tables do
    # Manga <-> Tags
    execute """
    CREATE TABLE contents.manga_tags (
      manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
      tag_id BIGINT NOT NULL REFERENCES contents.tags(id) ON DELETE CASCADE,
      rank INTEGER CHECK (rank IS NULL OR (rank >= 0 AND rank <= 100)),
      is_spoiler BOOLEAN DEFAULT FALSE,
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      PRIMARY KEY (manga_id, tag_id)
    )
    """, "DROP TABLE IF EXISTS contents.manga_tags CASCADE"

    # Manga <-> Demographics
    execute """
    CREATE TABLE contents.manga_demographics (
      manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
      demographic_id BIGINT NOT NULL REFERENCES contents.demographics(id) ON DELETE CASCADE,
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      PRIMARY KEY (manga_id, demographic_id)
    )
    """, "DROP TABLE IF EXISTS contents.manga_demographics CASCADE"

    # Manga <-> Characters
    execute """
    CREATE TABLE contents.manga_characters (
      manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
      character_id BIGINT NOT NULL REFERENCES contents.characters(id) ON DELETE CASCADE,
      role contents.character_role DEFAULT 'supporting',
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      PRIMARY KEY (manga_id, character_id)
    )
    """, "DROP TABLE IF EXISTS contents.manga_characters CASCADE"

    # Manga <-> Staff (Authors, Artists)
    execute """
    CREATE TABLE contents.manga_staff (
      id BIGSERIAL PRIMARY KEY,
      manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
      person_id BIGINT NOT NULL REFERENCES contents.people(id) ON DELETE CASCADE,
      role VARCHAR(200) NOT NULL,
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      UNIQUE (manga_id, person_id, role)
    )
    """, "DROP TABLE IF EXISTS contents.manga_staff CASCADE"
  end

  # ============================================================================
  # CONTENT RELATIONS TABLE (Sequels, Prequels, etc.)
  # ============================================================================
  defp create_content_relations_table do
    execute """
    CREATE TABLE contents.content_relations (
      id BIGSERIAL PRIMARY KEY,

      -- Source (one of these will be set)
      source_anime_id BIGINT REFERENCES contents.anime(id) ON DELETE CASCADE,
      source_manga_id BIGINT REFERENCES contents.manga(id) ON DELETE CASCADE,

      -- Target (one of these will be set)
      target_anime_id BIGINT REFERENCES contents.anime(id) ON DELETE CASCADE,
      target_manga_id BIGINT REFERENCES contents.manga(id) ON DELETE CASCADE,

      -- Relation type
      relation_type contents.relation_type NOT NULL,

      -- Metadata
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),

      -- Constraints
      CONSTRAINT content_relations_source_check CHECK (
        (source_anime_id IS NOT NULL AND source_manga_id IS NULL) OR
        (source_anime_id IS NULL AND source_manga_id IS NOT NULL)
      ),
      CONSTRAINT content_relations_target_check CHECK (
        (target_anime_id IS NOT NULL AND target_manga_id IS NULL) OR
        (target_anime_id IS NULL AND target_manga_id IS NOT NULL)
      ),
      -- Unique constraint for upsert
      UNIQUE NULLS NOT DISTINCT (source_anime_id, source_manga_id, target_anime_id, target_manga_id, relation_type)
    )
    """, "DROP TABLE IF EXISTS contents.content_relations CASCADE"
  end

  # ============================================================================
  # AIRING SCHEDULE TABLE
  # ============================================================================
  defp create_airing_schedule_table do
    execute """
    CREATE TABLE contents.airing_schedule (
      id BIGSERIAL PRIMARY KEY,
      anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
      anilist_id INTEGER,
      episode INTEGER NOT NULL CHECK (episode > 0),
      airing_at TIMESTAMP(0) NOT NULL,
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      UNIQUE (anime_id, episode)
    )
    """, "DROP TABLE IF EXISTS contents.airing_schedule CASCADE"
  end

  # ============================================================================
  # INDEXES
  # ============================================================================
  defp create_indexes do
    # Anime indexes
    execute "CREATE INDEX idx_anime_mal_id ON contents.anime (mal_id) WHERE mal_id IS NOT NULL"
    execute "CREATE UNIQUE INDEX idx_anime_anilist_id ON contents.anime (anilist_id)"
    execute "CREATE INDEX idx_anime_title_en_trgm ON contents.anime USING GIN (title_en gin_trgm_ops)"
    execute "CREATE INDEX idx_anime_title_ja_trgm ON contents.anime USING GIN (title_ja gin_trgm_ops) WHERE title_ja IS NOT NULL"
    execute "CREATE INDEX idx_anime_title_romaji_trgm ON contents.anime USING GIN (title_romaji gin_trgm_ops) WHERE title_romaji IS NOT NULL"
    execute "CREATE INDEX idx_anime_search_vector ON contents.anime USING GIN (search_vector)"
    execute "CREATE INDEX idx_anime_format ON contents.anime (format) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_status ON contents.anime (status) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_season ON contents.anime (season_year DESC, season) WHERE deleted_at IS NULL AND season IS NOT NULL"
    execute "CREATE INDEX idx_anime_Animetana_score_en ON contents.anime (Animetana_score_en DESC) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_Animetana_score_ja ON contents.anime (Animetana_score_ja DESC) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_Animetana_rank_en ON contents.anime (Animetana_rank_en) WHERE Animetana_rank_en IS NOT NULL AND deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_Animetana_rank_ja ON contents.anime (Animetana_rank_ja) WHERE Animetana_rank_ja IS NOT NULL AND deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_Animetana_popularity_en ON contents.anime (Animetana_popularity_en) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_Animetana_popularity_ja ON contents.anime (Animetana_popularity_ja) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_trending ON contents.anime (trending_score DESC) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_next_airing ON contents.anime (next_airing_at) WHERE next_airing_at IS NOT NULL AND deleted_at IS NULL"

    # Manga indexes
    execute "CREATE INDEX idx_manga_mal_id ON contents.manga (mal_id) WHERE mal_id IS NOT NULL"
    execute "CREATE UNIQUE INDEX idx_manga_anilist_id ON contents.manga (anilist_id)"
    execute "CREATE INDEX idx_manga_title_en_trgm ON contents.manga USING GIN (title_en gin_trgm_ops)"
    execute "CREATE INDEX idx_manga_title_ja_trgm ON contents.manga USING GIN (title_ja gin_trgm_ops) WHERE title_ja IS NOT NULL"
    execute "CREATE INDEX idx_manga_title_romaji_trgm ON contents.manga USING GIN (title_romaji gin_trgm_ops) WHERE title_romaji IS NOT NULL"
    execute "CREATE INDEX idx_manga_search_vector ON contents.manga USING GIN (search_vector)"
    execute "CREATE INDEX idx_manga_format ON contents.manga (format) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_status ON contents.manga (status) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_Animetana_score_en ON contents.manga (Animetana_score_en DESC) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_Animetana_score_ja ON contents.manga (Animetana_score_ja DESC) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_Animetana_rank_en ON contents.manga (Animetana_rank_en) WHERE Animetana_rank_en IS NOT NULL AND deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_Animetana_rank_ja ON contents.manga (Animetana_rank_ja) WHERE Animetana_rank_ja IS NOT NULL AND deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_Animetana_popularity_en ON contents.manga (Animetana_popularity_en) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_Animetana_popularity_ja ON contents.manga (Animetana_popularity_ja) WHERE deleted_at IS NULL"

    # Episodes indexes
    execute "CREATE INDEX idx_episodes_anime ON contents.episodes (anime_id)"
    execute "CREATE INDEX idx_episodes_aired ON contents.episodes (aired_at DESC) WHERE deleted_at IS NULL"

    # Chapters indexes
    execute "CREATE INDEX idx_chapters_manga ON contents.chapters (manga_id)"

    # People indexes
    execute "CREATE INDEX idx_people_mal_id ON contents.people (mal_id) WHERE mal_id IS NOT NULL"
    execute "CREATE UNIQUE INDEX idx_people_anilist_id ON contents.people (anilist_id)"
    execute "CREATE INDEX idx_people_name_en_trgm ON contents.people USING GIN (name_en gin_trgm_ops)"

    # Characters indexes
    execute "CREATE INDEX idx_characters_mal_id ON contents.characters (mal_id) WHERE mal_id IS NOT NULL"
    execute "CREATE UNIQUE INDEX idx_characters_anilist_id ON contents.characters (anilist_id)"
    execute "CREATE INDEX idx_characters_name_en_trgm ON contents.characters USING GIN (name_en gin_trgm_ops)"

    # Studios indexes
    execute "CREATE INDEX idx_studios_mal_id ON contents.studios (mal_id) WHERE mal_id IS NOT NULL"
    execute "CREATE UNIQUE INDEX idx_studios_anilist_id ON contents.studios (anilist_id)"

    # Genres indexes
    # Tags indexes
    execute "CREATE UNIQUE INDEX idx_tags_anilist_id ON contents.tags (anilist_id)"
    execute "CREATE INDEX idx_tags_category ON contents.tags (category)"

    # Relationship table indexes
    execute "CREATE INDEX idx_anime_tags_tag ON contents.anime_tags (tag_id)"
    execute "CREATE INDEX idx_anime_tags_rank ON contents.anime_tags (anime_id, rank DESC) WHERE rank IS NOT NULL"
    execute "CREATE INDEX idx_anime_studios_studio ON contents.anime_studios (studio_id)"
    execute "CREATE INDEX idx_anime_characters_character ON contents.anime_characters (character_id)"
    execute "CREATE INDEX idx_anime_staff_person ON contents.anime_staff (person_id)"
    execute "CREATE INDEX idx_character_voice_actors_character ON contents.character_voice_actors (character_id)"
    execute "CREATE INDEX idx_character_voice_actors_person ON contents.character_voice_actors (person_id)"

    execute "CREATE INDEX idx_manga_tags_tag ON contents.manga_tags (tag_id)"
    execute "CREATE INDEX idx_manga_characters_character ON contents.manga_characters (character_id)"
    execute "CREATE INDEX idx_manga_staff_person ON contents.manga_staff (person_id)"

    # Content relations indexes
    execute "CREATE INDEX idx_content_relations_source_anime ON contents.content_relations (source_anime_id) WHERE source_anime_id IS NOT NULL"
    execute "CREATE INDEX idx_content_relations_source_manga ON contents.content_relations (source_manga_id) WHERE source_manga_id IS NOT NULL"
    execute "CREATE INDEX idx_content_relations_target_anime ON contents.content_relations (target_anime_id) WHERE target_anime_id IS NOT NULL"
    execute "CREATE INDEX idx_content_relations_target_manga ON contents.content_relations (target_manga_id) WHERE target_manga_id IS NOT NULL"

    # Airing schedule indexes
    execute "CREATE INDEX idx_airing_schedule_anime ON contents.airing_schedule (anime_id)"
    execute "CREATE INDEX idx_airing_schedule_airing_at ON contents.airing_schedule (airing_at DESC)"

  end

  # ============================================================================
  # FUNCTIONS
  # ============================================================================
  defp create_functions do
    # Updated at trigger function
    execute """
    CREATE OR REPLACE FUNCTION contents.update_updated_at() RETURNS TRIGGER AS $$
    BEGIN
      NEW.updated_at = NOW();
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS contents.update_updated_at()"

    # Search vector update function for anime
    execute """
    CREATE OR REPLACE FUNCTION contents.update_anime_search_vector() RETURNS TRIGGER AS $$
    BEGIN
      NEW.search_vector :=
        setweight(to_tsvector('english', COALESCE(NEW.title_en, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(NEW.title_ja, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.title_romaji, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.synopsis_en, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(array_to_string(NEW.title_synonyms, ' '), '')), 'B');
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS contents.update_anime_search_vector()"

    # Search vector update function for manga
    execute """
    CREATE OR REPLACE FUNCTION contents.update_manga_search_vector() RETURNS TRIGGER AS $$
    BEGIN
      NEW.search_vector :=
        setweight(to_tsvector('english', COALESCE(NEW.title_en, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(NEW.title_ja, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.title_romaji, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.synopsis_en, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(array_to_string(NEW.title_synonyms, ' '), '')), 'B');
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS contents.update_manga_search_vector()"
  end

  # ============================================================================
  # TRIGGERS
  # ============================================================================
  defp create_triggers do
    # Updated at triggers
    ~w(anime manga episodes chapters people characters studios tags demographics)
    |> Enum.each(fn table ->
      execute """
      CREATE TRIGGER #{table}_updated_at_trigger
        BEFORE UPDATE ON contents.#{table}
        FOR EACH ROW EXECUTE FUNCTION contents.update_updated_at()
      """
    end)

    # Search vector triggers
    execute """
    CREATE TRIGGER anime_search_vector_trigger
      BEFORE INSERT OR UPDATE OF title_en, title_ja, title_romaji, synopsis_en, title_synonyms
      ON contents.anime
      FOR EACH ROW EXECUTE FUNCTION contents.update_anime_search_vector()
    """

    execute """
    CREATE TRIGGER manga_search_vector_trigger
      BEFORE INSERT OR UPDATE OF title_en, title_ja, title_romaji, synopsis_en, title_synonyms
      ON contents.manga
      FOR EACH ROW EXECUTE FUNCTION contents.update_manga_search_vector()
    """
  end
end
