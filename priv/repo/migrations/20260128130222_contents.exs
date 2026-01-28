defmodule Yunaos.Repo.Migrations.Contents do
  use Ecto.Migration

  def change do
    # ============================================================================
    # SCHEMA CREATION
    # ============================================================================
    execute "CREATE SCHEMA IF NOT EXISTS contents", "DROP SCHEMA IF EXISTS contents CASCADE"

    # ============================================================================
    # EXTENSIONS
    # ============================================================================
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm", "DROP EXTENSION IF EXISTS pg_trgm"
    execute "CREATE EXTENSION IF NOT EXISTS btree_gin", "DROP EXTENSION IF EXISTS btree_gin"
    execute "CREATE EXTENSION IF NOT EXISTS btree_gist", "DROP EXTENSION IF EXISTS btree_gist"

    # ============================================================================
    # ENUM TYPE DEFINITIONS
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
    # PEOPLE AND CHARACTERS
    # ============================================================================
    create_people_table()
    create_characters_table()

    # ============================================================================
    # PRODUCTION AND METADATA
    # ============================================================================
    create_studios_table()
    create_genres_table()
    create_demographics_table()
    create_themes_table()
    create_sub_genres_table()
    create_magazines_table()

    # ============================================================================
    # RELATIONSHIP TABLES
    # ============================================================================
    create_relationship_tables()

    # ============================================================================
    # CONTENT RELATIONSHIPS
    # ============================================================================
    create_content_relation_tables()

    # ============================================================================
    # ANALYTICS AND METRICS
    # ============================================================================
    create_score_distribution_tables()

    # ============================================================================
    # PICTURES/IMAGES
    # ============================================================================
    create_picture_tables()

    # ============================================================================
    # AUDIT AND HISTORY
    # ============================================================================
    create_history_tables()

    # ============================================================================
    # SYNC AND DATA MANAGEMENT
    # ============================================================================
    create_sync_tables()

    # ============================================================================
    # INDEXES
    # ============================================================================
    create_all_indexes()

    # ============================================================================
    # FUNCTIONS
    # ============================================================================
    create_functions()

    # ============================================================================
    # TRIGGERS
    # ============================================================================
    create_triggers()

    # ============================================================================
    # MATERIALIZED VIEWS
    # ============================================================================
    create_materialized_views()

    # ============================================================================
    # HELPER FUNCTIONS
    # ============================================================================
    create_helper_functions()

    # ============================================================================
    # COMMENTS
    # ============================================================================
    create_comments()
  end

  # ============================================================================
  # ENUM TYPES
  # ============================================================================
  defp create_enum_types do
    # Anime types
    execute """
    CREATE TYPE contents.anime_type AS ENUM (
        'tv', 'movie', 'ova', 'ona', 'special', 'tv_special', 'music', 'cm', 'pv', 'unknown'
    )
    """, "DROP TYPE IF EXISTS contents.anime_type"

    # Anime airing status
    execute """
    CREATE TYPE contents.anime_status AS ENUM (
        'airing', 'finished', 'upcoming', 'unknown'
    )
    """, "DROP TYPE IF EXISTS contents.anime_status"

    # Anime age rating
    execute """
    CREATE TYPE contents.anime_rating AS ENUM (
        'g', 'pg', 'pg13', 'r17', 'r_plus', 'rx', 'unknown'
    )
    """, "DROP TYPE IF EXISTS contents.anime_rating"

    # Manga types
    execute """
    CREATE TYPE contents.manga_type AS ENUM (
        'manga', 'manhwa', 'manhua', 'light_novel', 'novel', 'one_shot', 'doujinshi', 'unknown'
    )
    """, "DROP TYPE IF EXISTS contents.manga_type"

    # Manga publication status
    execute """
    CREATE TYPE contents.manga_status AS ENUM (
        'publishing', 'finished', 'hiatus', 'discontinued', 'upcoming', 'unknown'
    )
    """, "DROP TYPE IF EXISTS contents.manga_status"

    # Season enum
    execute """
    CREATE TYPE contents.season AS ENUM (
        'winter', 'spring', 'summer', 'fall'
    )
    """, "DROP TYPE IF EXISTS contents.season"

    # Content source material
    execute """
    CREATE TYPE contents.source_material AS ENUM (
        'original', 'manga', 'light_novel', 'visual_novel', 'video_game', 'novel',
        'web_manga', 'web_novel', 'four_koma', 'picture_book', 'music', 'mixed_media',
        'book', 'card_game', 'radio', 'other', 'unknown'
    )
    """, "DROP TYPE IF EXISTS contents.source_material"

    # Character role types
    execute """
    CREATE TYPE contents.character_role AS ENUM (
        'main', 'supporting', 'background'
    )
    """, "DROP TYPE IF EXISTS contents.character_role"

    # Studio role types
    execute """
    CREATE TYPE contents.studio_role AS ENUM (
        'main_studio', 'co_producer', 'producer', 'licensor', 'studio'
    )
    """, "DROP TYPE IF EXISTS contents.studio_role"

    # Publisher role types
    execute """
    CREATE TYPE contents.publisher_role AS ENUM (
        'publisher', 'serializer', 'licensor'
    )
    """, "DROP TYPE IF EXISTS contents.publisher_role"

    # Staff position types
    execute """
    CREATE TYPE contents.staff_position AS ENUM (
        'director', 'producer', 'writer', 'music', 'character_design', 'animation_director',
        'art_director', 'sound_director', 'episode_director', 'storyboard', 'key_animation',
        'original_creator', 'other'
    )
    """, "DROP TYPE IF EXISTS contents.staff_position"

    # Manga staff position types
    execute """
    CREATE TYPE contents.manga_staff_position AS ENUM (
        'author', 'artist', 'author_artist', 'original_creator', 'other'
    )
    """, "DROP TYPE IF EXISTS contents.manga_staff_position"

    # Relation types between content
    execute """
    CREATE TYPE contents.content_relation AS ENUM (
        'sequel', 'prequel', 'alternative_setting', 'alternative_version', 'side_story',
        'parent_story', 'summary', 'full_story', 'spin_off', 'adaptation', 'character', 'other'
    )
    """, "DROP TYPE IF EXISTS contents.content_relation"

    # Sync status
    execute """
    CREATE TYPE contents.sync_status AS ENUM (
        'pending', 'syncing', 'completed', 'failed', 'skipped'
    )
    """, "DROP TYPE IF EXISTS contents.sync_status"

    # Pacing classification
    execute """
    CREATE TYPE contents.pacing_type AS ENUM (
        'fast', 'medium', 'slow'
    )
    """, "DROP TYPE IF EXISTS contents.pacing_type"

    # Target audience
    execute """
    CREATE TYPE contents.target_audience AS ENUM (
        'kids', 'teens', 'adults', 'all_ages'
    )
    """, "DROP TYPE IF EXISTS contents.target_audience"

    # Voice acting language
    execute """
    CREATE TYPE contents.voice_language AS ENUM (
        'japanese', 'english', 'korean', 'chinese', 'spanish', 'french',
        'german', 'italian', 'portuguese', 'other'
    )
    """, "DROP TYPE IF EXISTS contents.voice_language"

    # Gender enum
    execute """
    CREATE TYPE contents.gender AS ENUM (
        'male', 'female', 'non_binary', 'unknown'
    )
    """, "DROP TYPE IF EXISTS contents.gender"

    # Studio/Company type
    execute """
    CREATE TYPE contents.company_type AS ENUM (
        'animation_studio', 'production_company', 'publisher', 'licensor', 'other'
    )
    """, "DROP TYPE IF EXISTS contents.company_type"

    # Genre category type
    execute """
    CREATE TYPE contents.genre_category AS ENUM (
        'anime', 'manga', 'both'
    )
    """, "DROP TYPE IF EXISTS contents.genre_category"
  end

  # ============================================================================
  # ANIME TABLE
  # ============================================================================
  defp create_anime_table do
    execute """
    CREATE TABLE contents.anime (
        id BIGSERIAL PRIMARY KEY,

        -- External IDs
        mal_id INTEGER,
        anilist_id INTEGER,
        kitsu_id INTEGER,

        -- Core identification
        title_en VARCHAR(500) NOT NULL,
        title_ja VARCHAR(500),
        title_romaji VARCHAR(500),
        title_synonyms TEXT[] DEFAULT ARRAY[]::TEXT[],

        -- Content descriptions
        synopsis_en TEXT,
        synopsis_ja TEXT,
        background_en TEXT,
        background_ja TEXT,

        -- Media assets
        cover_image_url VARCHAR(1000),
        banner_image_url VARCHAR(1000),
        trailer_url VARCHAR(1000),

        -- Classification
        type contents.anime_type NOT NULL DEFAULT 'unknown',
        source contents.source_material DEFAULT 'unknown',
        status contents.anime_status NOT NULL DEFAULT 'upcoming',
        rating contents.anime_rating,

        -- Episode information
        episodes INTEGER CHECK (episodes IS NULL OR episodes >= 0),
        duration INTEGER CHECK (duration IS NULL OR duration >= 0),

        -- Release information
        start_date DATE,
        end_date DATE,
        season contents.season,
        season_year INTEGER CHECK (season_year IS NULL OR (season_year >= 1900 AND season_year <= 2100)),
        broadcast_day VARCHAR(20),
        broadcast_time TIME(0),

        -- External scores/stats (from MAL)
        mal_score NUMERIC(4,2) CHECK (mal_score IS NULL OR (mal_score >= 0 AND mal_score <= 10)),
        mal_scored_by INTEGER DEFAULT 0 CHECK (mal_scored_by >= 0),
        mal_rank INTEGER CHECK (mal_rank IS NULL OR mal_rank >= 0),
        mal_popularity INTEGER CHECK (mal_popularity IS NULL OR mal_popularity >= 0),
        mal_members INTEGER DEFAULT 0 CHECK (mal_members >= 0),
        mal_favorites INTEGER DEFAULT 0 CHECK (mal_favorites >= 0),

        -- Internal app rankings/scores
        internal_score NUMERIC(4,2) DEFAULT 0.0 CHECK (internal_score >= 0 AND internal_score <= 10),
        internal_scored_by INTEGER DEFAULT 0 CHECK (internal_scored_by >= 0),
        internal_rank INTEGER CHECK (internal_rank IS NULL OR internal_rank >= 0),
        internal_popularity INTEGER CHECK (internal_popularity IS NULL OR internal_popularity >= 0),
        internal_trending_score NUMERIC(5,2) DEFAULT 0.0 CHECK (internal_trending_score >= 0),
        internal_recommendation_score NUMERIC(5,2) DEFAULT 0.0 CHECK (internal_recommendation_score >= 0),

        -- Internal aggregated stats
        average_rating NUMERIC(4,2) DEFAULT 0.0 CHECK (average_rating >= 0 AND average_rating <= 10),
        rating_count INTEGER DEFAULT 0 CHECK (rating_count >= 0),
        members_count INTEGER DEFAULT 0 CHECK (members_count >= 0),
        favorites_count INTEGER DEFAULT 0 CHECK (favorites_count >= 0),
        completed_count INTEGER DEFAULT 0 CHECK (completed_count >= 0),
        watching_count INTEGER DEFAULT 0 CHECK (watching_count >= 0),
        plan_to_watch_count INTEGER DEFAULT 0 CHECK (plan_to_watch_count >= 0),

        -- Additional internal metrics
        view_count BIGINT DEFAULT 0 CHECK (view_count >= 0),
        interaction_count INTEGER DEFAULT 0 CHECK (interaction_count >= 0),
        bookmark_count INTEGER DEFAULT 0 CHECK (bookmark_count >= 0),
        weekly_trend_change INTEGER DEFAULT 0,
        monthly_trend_change INTEGER DEFAULT 0,

        -- Algorithm weights
        quality_score NUMERIC(5,2) DEFAULT 0.0 CHECK (quality_score >= 0),
        engagement_score NUMERIC(5,2) DEFAULT 0.0 CHECK (engagement_score >= 0),
        recency_boost NUMERIC(3,2) DEFAULT 1.0 CHECK (recency_boost >= 0),

        -- Search
        search_vector TSVECTOR,

        -- Additional metadata
        more_info_en TEXT,
        more_info_ja TEXT,
        opening_themes TEXT[] DEFAULT ARRAY[]::TEXT[],
        ending_themes TEXT[] DEFAULT ARRAY[]::TEXT[],

        -- Structured metadata (JSONB)
        external_links JSONB DEFAULT '[]'::JSONB,
        streaming_links JSONB DEFAULT '[]'::JSONB,
        mood_tags JSONB DEFAULT '[]'::JSONB,
        content_warnings JSONB DEFAULT '[]'::JSONB,
        similar_to JSONB DEFAULT '[]'::JSONB,
        fun_facts JSONB DEFAULT '[]'::JSONB,

        -- Content classification
        pacing contents.pacing_type,
        art_style_en TEXT,
        art_style_ja TEXT,
        target_audience contents.target_audience,

        -- Soft delete support
        deleted_at TIMESTAMP(0),
        deletion_reason VARCHAR(255),

        -- System fields
        enriched BOOLEAN DEFAULT FALSE,
        last_synced_at TIMESTAMP(0),
        sync_status contents.sync_status DEFAULT 'pending',
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),

        -- Constraints
        CONSTRAINT anime_dates_check CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date),
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

        -- Core identification
        title_en VARCHAR(500) NOT NULL,
        title_ja VARCHAR(500),
        title_romaji VARCHAR(500),
        title_synonyms TEXT[] DEFAULT ARRAY[]::TEXT[],

        -- Content descriptions
        synopsis_en TEXT,
        synopsis_ja TEXT,
        background_en TEXT,
        background_ja TEXT,

        -- Media assets
        cover_image_url VARCHAR(1000),
        banner_image_url VARCHAR(1000),

        -- Classification
        type contents.manga_type NOT NULL DEFAULT 'manga',
        status contents.manga_status NOT NULL DEFAULT 'publishing',

        -- Chapter/Volume information
        chapters INTEGER CHECK (chapters IS NULL OR chapters >= 0),
        volumes INTEGER CHECK (volumes IS NULL OR volumes >= 0),
        published_from DATE,
        published_to DATE,

        -- External scores/stats (from MAL)
        mal_score NUMERIC(4,2) CHECK (mal_score IS NULL OR (mal_score >= 0 AND mal_score <= 10)),
        mal_scored_by INTEGER DEFAULT 0 CHECK (mal_scored_by >= 0),
        mal_rank INTEGER CHECK (mal_rank IS NULL OR mal_rank >= 0),
        mal_popularity INTEGER CHECK (mal_popularity IS NULL OR mal_popularity >= 0),
        mal_members INTEGER DEFAULT 0 CHECK (mal_members >= 0),
        mal_favorites INTEGER DEFAULT 0 CHECK (mal_favorites >= 0),

        -- Internal app rankings/scores
        internal_score NUMERIC(4,2) DEFAULT 0.0 CHECK (internal_score >= 0 AND internal_score <= 10),
        internal_scored_by INTEGER DEFAULT 0 CHECK (internal_scored_by >= 0),
        internal_rank INTEGER CHECK (internal_rank IS NULL OR internal_rank >= 0),
        internal_popularity INTEGER CHECK (internal_popularity IS NULL OR internal_popularity >= 0),
        internal_trending_score NUMERIC(5,2) DEFAULT 0.0 CHECK (internal_trending_score >= 0),
        internal_recommendation_score NUMERIC(5,2) DEFAULT 0.0 CHECK (internal_recommendation_score >= 0),

        -- Internal aggregated stats
        average_rating NUMERIC(4,2) DEFAULT 0.0 CHECK (average_rating >= 0 AND average_rating <= 10),
        rating_count INTEGER DEFAULT 0 CHECK (rating_count >= 0),
        members_count INTEGER DEFAULT 0 CHECK (members_count >= 0),
        favorites_count INTEGER DEFAULT 0 CHECK (favorites_count >= 0),
        completed_count INTEGER DEFAULT 0 CHECK (completed_count >= 0),
        reading_count INTEGER DEFAULT 0 CHECK (reading_count >= 0),
        plan_to_read_count INTEGER DEFAULT 0 CHECK (plan_to_read_count >= 0),

        -- Additional internal metrics
        view_count BIGINT DEFAULT 0 CHECK (view_count >= 0),
        interaction_count INTEGER DEFAULT 0 CHECK (interaction_count >= 0),
        bookmark_count INTEGER DEFAULT 0 CHECK (bookmark_count >= 0),
        weekly_trend_change INTEGER DEFAULT 0,
        monthly_trend_change INTEGER DEFAULT 0,

        -- Algorithm weights
        quality_score NUMERIC(5,2) DEFAULT 0.0 CHECK (quality_score >= 0),
        engagement_score NUMERIC(5,2) DEFAULT 0.0 CHECK (engagement_score >= 0),
        recency_boost NUMERIC(3,2) DEFAULT 1.0 CHECK (recency_boost >= 0),

        -- Search
        search_vector TSVECTOR,

        -- Additional metadata
        more_info_en TEXT,
        more_info_ja TEXT,

        -- Structured metadata (JSONB)
        mood_tags JSONB DEFAULT '[]'::JSONB,
        content_warnings JSONB DEFAULT '[]'::JSONB,
        similar_to JSONB DEFAULT '[]'::JSONB,
        fun_facts JSONB DEFAULT '[]'::JSONB,

        -- Content classification
        pacing contents.pacing_type,
        art_style_en TEXT,
        art_style_ja TEXT,
        target_audience contents.target_audience,

        -- Soft delete support
        deleted_at TIMESTAMP(0),
        deletion_reason VARCHAR(255),

        -- System fields
        enriched BOOLEAN DEFAULT FALSE,
        last_synced_at TIMESTAMP(0),
        sync_status contents.sync_status DEFAULT 'pending',
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),

        -- Constraints
        CONSTRAINT manga_dates_check CHECK (published_to IS NULL OR published_from IS NULL OR published_to >= published_from)
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

        -- Episode information
        episode_number NUMERIC(8,2) NOT NULL CHECK (episode_number > 0),
        title_en VARCHAR(500),
        title_ja VARCHAR(500),
        title_romaji VARCHAR(500),
        synopsis_en TEXT,
        synopsis_ja TEXT,

        -- Media
        thumbnail_url VARCHAR(1000),

        -- Release information
        aired DATE,
        duration INTEGER CHECK (duration IS NULL OR duration >= 0),

        -- Stats
        average_rating NUMERIC(4,2) DEFAULT 0.0 CHECK (average_rating >= 0 AND average_rating <= 10),
        rating_count INTEGER DEFAULT 0 CHECK (rating_count >= 0),

        -- Classification
        is_filler BOOLEAN DEFAULT FALSE,
        is_recap BOOLEAN DEFAULT FALSE,

        -- Soft delete
        deleted_at TIMESTAMP(0),

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
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

        -- Chapter information
        chapter_number NUMERIC(8,2) NOT NULL CHECK (chapter_number > 0),
        volume_number INTEGER CHECK (volume_number IS NULL OR volume_number >= 0),
        title_en VARCHAR(500),
        title_ja VARCHAR(500),
        title_romaji VARCHAR(500),
        synopsis_en TEXT,
        synopsis_ja TEXT,

        -- Content information
        page_count INTEGER CHECK (page_count IS NULL OR page_count >= 0),
        published DATE,

        -- Stats
        average_rating NUMERIC(4,2) DEFAULT 0.0 CHECK (average_rating >= 0 AND average_rating <= 10),
        rating_count INTEGER DEFAULT 0 CHECK (rating_count >= 0),

        -- Soft delete
        deleted_at TIMESTAMP(0),

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.chapters CASCADE"
  end

  # ============================================================================
  # PEOPLE TABLE
  # ============================================================================
  defp create_people_table do
    execute """
    CREATE TABLE contents.people (
        id BIGSERIAL PRIMARY KEY,

        -- External IDs
        mal_id INTEGER,
        anilist_id INTEGER,

        -- Basic information
        name_en VARCHAR(200) NOT NULL,
        name_ja VARCHAR(200),
        given_name VARCHAR(100),
        family_name VARCHAR(100),
        alternate_names TEXT[] DEFAULT ARRAY[]::TEXT[],

        -- Personal information
        birthday DATE,
        death_date DATE,
        gender contents.gender,
        blood_type VARCHAR(10),
        height VARCHAR(20),
        weight VARCHAR(20),
        measurements VARCHAR(50),
        hometown_en VARCHAR(200),
        hometown_ja VARCHAR(200),

        -- Professional information
        website_url VARCHAR(500),
        image_url VARCHAR(1000),
        about_en TEXT,
        about_ja TEXT,
        notable_works JSONB DEFAULT '[]'::JSONB,

        -- Social media
        social_twitter VARCHAR(500),
        social_instagram VARCHAR(500),
        social_youtube VARCHAR(500),
        social_tiktok VARCHAR(500),
        social_website VARCHAR(500),

        -- Stats
        favorites_count INTEGER DEFAULT 0 CHECK (favorites_count >= 0),

        -- Soft delete
        deleted_at TIMESTAMP(0),

        -- System fields
        enriched BOOLEAN DEFAULT FALSE,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),

        -- Constraints
        CONSTRAINT people_dates_check CHECK (death_date IS NULL OR birthday IS NULL OR death_date >= birthday)
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

        -- Basic information
        name_en VARCHAR(200) NOT NULL,
        name_ja VARCHAR(200),
        name_kanji VARCHAR(200),
        nicknames TEXT[] DEFAULT ARRAY[]::TEXT[],

        -- Character information
        about_en TEXT,
        about_ja TEXT,
        role_description_en TEXT,
        role_description_ja TEXT,
        image_url VARCHAR(1000),
        personality_tags JSONB DEFAULT '[]'::JSONB,

        -- Physical characteristics
        gender contents.gender,
        age VARCHAR(50),
        height VARCHAR(20),
        weight VARCHAR(20),
        blood_type VARCHAR(10),
        measurements VARCHAR(50),

        -- Stats
        favorites_count INTEGER DEFAULT 0 CHECK (favorites_count >= 0),

        -- Soft delete
        deleted_at TIMESTAMP(0),

        -- System fields
        enriched BOOLEAN DEFAULT FALSE,
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

        -- Basic information
        name_en VARCHAR(200) NOT NULL,
        name_ja VARCHAR(200),
        type contents.company_type NOT NULL DEFAULT 'animation_studio',

        -- Company information
        established DATE,
        dissolved DATE,
        website_url VARCHAR(500),
        about_en TEXT,
        about_ja TEXT,

        -- Stats
        anime_count INTEGER DEFAULT 0 CHECK (anime_count >= 0),
        average_score NUMERIC(4,2) CHECK (average_score IS NULL OR (average_score >= 0 AND average_score <= 10)),

        -- Soft delete
        deleted_at TIMESTAMP(0),

        -- System fields
        enriched BOOLEAN DEFAULT FALSE,
        last_synced_at TIMESTAMP(0),
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),

        -- Constraints
        CONSTRAINT studios_dates_check CHECK (dissolved IS NULL OR established IS NULL OR dissolved >= established)
    )
    """, "DROP TABLE IF EXISTS contents.studios CASCADE"
  end

  # ============================================================================
  # GENRES TABLE
  # ============================================================================
  defp create_genres_table do
    execute """
    CREATE TABLE contents.genres (
        id BIGSERIAL PRIMARY KEY,

        -- External IDs
        mal_id INTEGER NOT NULL,
        anilist_id INTEGER,

        -- Basic information
        name_en VARCHAR(100) NOT NULL,
        name_ja VARCHAR(100),
        category contents.genre_category NOT NULL DEFAULT 'both',
        description_en TEXT,
        description_ja TEXT,

        -- Display order
        display_order INTEGER DEFAULT 0,

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.genres CASCADE"
  end

  # ============================================================================
  # DEMOGRAPHICS TABLE
  # ============================================================================
  defp create_demographics_table do
    execute """
    CREATE TABLE contents.demographics (
        id BIGSERIAL PRIMARY KEY,

        -- External IDs
        mal_id INTEGER NOT NULL,
        anilist_id INTEGER,

        -- Basic information
        name_en VARCHAR(100) NOT NULL,
        name_ja VARCHAR(100),
        category contents.genre_category NOT NULL DEFAULT 'both',
        description_en TEXT,
        description_ja TEXT,

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.demographics CASCADE"
  end

  # ============================================================================
  # THEMES TABLE
  # ============================================================================
  defp create_themes_table do
    execute """
    CREATE TABLE contents.themes (
        id BIGSERIAL PRIMARY KEY,

        -- External IDs
        mal_id INTEGER NOT NULL,
        anilist_id INTEGER,

        -- Basic information
        name_en VARCHAR(100) NOT NULL,
        name_ja VARCHAR(100),
        category contents.genre_category NOT NULL DEFAULT 'both',
        description_en TEXT,
        description_ja TEXT,

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.themes CASCADE"
  end

  # ============================================================================
  # SUB-GENRES TABLE
  # ============================================================================
  defp create_sub_genres_table do
    execute """
    CREATE TABLE contents.sub_genres (
        id BIGSERIAL PRIMARY KEY,

        -- Basic information
        name_en VARCHAR(100) NOT NULL,
        name_ja VARCHAR(100),
        description_en TEXT,
        description_ja TEXT,

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.sub_genres CASCADE"
  end

  # ============================================================================
  # MAGAZINES TABLE
  # ============================================================================
  defp create_magazines_table do
    execute """
    CREATE TABLE contents.magazines (
        id BIGSERIAL PRIMARY KEY,

        -- External IDs
        mal_id INTEGER NOT NULL,

        -- Basic information
        name_en VARCHAR(200) NOT NULL,
        name_ja VARCHAR(200),
        url VARCHAR(1000),
        about_en TEXT,
        about_ja TEXT,

        -- Stats
        count INTEGER DEFAULT 0 CHECK (count >= 0),

        -- Soft delete
        deleted_at TIMESTAMP(0),

        -- System fields
        enriched BOOLEAN DEFAULT FALSE,
        last_synced_at TIMESTAMP(0),
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.magazines CASCADE"
  end

  # ============================================================================
  # RELATIONSHIP TABLES
  # ============================================================================
  defp create_relationship_tables do
    # Anime-Genre relationships
    execute """
    CREATE TABLE contents.anime_genres (
        anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
        genre_id BIGINT NOT NULL REFERENCES contents.genres(id) ON DELETE CASCADE,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (anime_id, genre_id)
    )
    """, "DROP TABLE IF EXISTS contents.anime_genres CASCADE"

    # Anime-Demographics relationships
    execute """
    CREATE TABLE contents.anime_demographics (
        anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
        demographic_id BIGINT NOT NULL REFERENCES contents.demographics(id) ON DELETE CASCADE,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (anime_id, demographic_id)
    )
    """, "DROP TABLE IF EXISTS contents.anime_demographics CASCADE"

    # Anime-Themes relationships
    execute """
    CREATE TABLE contents.anime_themes (
        anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
        theme_id BIGINT NOT NULL REFERENCES contents.themes(id) ON DELETE CASCADE,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (anime_id, theme_id)
    )
    """, "DROP TABLE IF EXISTS contents.anime_themes CASCADE"

    # Anime-SubGenres relationships
    execute """
    CREATE TABLE contents.anime_sub_genres (
        anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
        sub_genre_id BIGINT NOT NULL REFERENCES contents.sub_genres(id) ON DELETE CASCADE,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (anime_id, sub_genre_id)
    )
    """, "DROP TABLE IF EXISTS contents.anime_sub_genres CASCADE"

    # Manga-Genre relationships
    execute """
    CREATE TABLE contents.manga_genres (
        manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
        genre_id BIGINT NOT NULL REFERENCES contents.genres(id) ON DELETE CASCADE,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (manga_id, genre_id)
    )
    """, "DROP TABLE IF EXISTS contents.manga_genres CASCADE"

    # Manga-Demographics relationships
    execute """
    CREATE TABLE contents.manga_demographics (
        manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
        demographic_id BIGINT NOT NULL REFERENCES contents.demographics(id) ON DELETE CASCADE,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (manga_id, demographic_id)
    )
    """, "DROP TABLE IF EXISTS contents.manga_demographics CASCADE"

    # Manga-Themes relationships
    execute """
    CREATE TABLE contents.manga_themes (
        manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
        theme_id BIGINT NOT NULL REFERENCES contents.themes(id) ON DELETE CASCADE,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (manga_id, theme_id)
    )
    """, "DROP TABLE IF EXISTS contents.manga_themes CASCADE"

    # Manga-SubGenres relationships
    execute """
    CREATE TABLE contents.manga_sub_genres (
        manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
        sub_genre_id BIGINT NOT NULL REFERENCES contents.sub_genres(id) ON DELETE CASCADE,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (manga_id, sub_genre_id)
    )
    """, "DROP TABLE IF EXISTS contents.manga_sub_genres CASCADE"

    # Genre-SubGenre hierarchical relationships
    execute """
    CREATE TABLE contents.genre_sub_genres (
        genre_id BIGINT NOT NULL REFERENCES contents.genres(id) ON DELETE CASCADE,
        sub_genre_id BIGINT NOT NULL REFERENCES contents.sub_genres(id) ON DELETE CASCADE,
        PRIMARY KEY (genre_id, sub_genre_id)
    )
    """, "DROP TABLE IF EXISTS contents.genre_sub_genres CASCADE"

    # Anime-Studio relationships
    execute """
    CREATE TABLE contents.anime_studios (
        anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
        studio_id BIGINT NOT NULL REFERENCES contents.studios(id) ON DELETE CASCADE,
        role contents.studio_role NOT NULL DEFAULT 'studio',
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (anime_id, studio_id, role)
    )
    """, "DROP TABLE IF EXISTS contents.anime_studios CASCADE"

    # Manga-Studio relationships
    execute """
    CREATE TABLE contents.manga_studios (
        manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
        studio_id BIGINT NOT NULL REFERENCES contents.studios(id) ON DELETE CASCADE,
        role contents.publisher_role NOT NULL DEFAULT 'publisher',
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (manga_id, studio_id, role)
    )
    """, "DROP TABLE IF EXISTS contents.manga_studios CASCADE"

    # Manga-Magazine relationships
    execute """
    CREATE TABLE contents.manga_magazines (
        manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
        magazine_id BIGINT NOT NULL REFERENCES contents.magazines(id) ON DELETE CASCADE,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (manga_id, magazine_id)
    )
    """, "DROP TABLE IF EXISTS contents.manga_magazines CASCADE"

    # Anime-Character relationships
    execute """
    CREATE TABLE contents.anime_characters (
        anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
        character_id BIGINT NOT NULL REFERENCES contents.characters(id) ON DELETE CASCADE,
        role contents.character_role NOT NULL DEFAULT 'supporting',
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (anime_id, character_id)
    )
    """, "DROP TABLE IF EXISTS contents.anime_characters CASCADE"

    # Manga-Character relationships
    execute """
    CREATE TABLE contents.manga_characters (
        manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
        character_id BIGINT NOT NULL REFERENCES contents.characters(id) ON DELETE CASCADE,
        role contents.character_role NOT NULL DEFAULT 'supporting',
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (manga_id, character_id)
    )
    """, "DROP TABLE IF EXISTS contents.manga_characters CASCADE"

    # Character-Voice Actor relationships
    execute """
    CREATE TABLE contents.character_voice_actors (
        character_id BIGINT NOT NULL REFERENCES contents.characters(id) ON DELETE CASCADE,
        person_id BIGINT NOT NULL REFERENCES contents.people(id) ON DELETE CASCADE,
        anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
        language contents.voice_language NOT NULL DEFAULT 'japanese',
        notes TEXT,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (character_id, person_id, anime_id, language)
    )
    """, "DROP TABLE IF EXISTS contents.character_voice_actors CASCADE"

    # Anime-Staff relationships
    execute """
    CREATE TABLE contents.anime_staff (
        anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
        person_id BIGINT NOT NULL REFERENCES contents.people(id) ON DELETE CASCADE,
        position contents.staff_position NOT NULL DEFAULT 'other',
        notes TEXT,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (anime_id, person_id, position)
    )
    """, "DROP TABLE IF EXISTS contents.anime_staff CASCADE"

    # Manga-Staff relationships
    execute """
    CREATE TABLE contents.manga_staff (
        manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
        person_id BIGINT NOT NULL REFERENCES contents.people(id) ON DELETE CASCADE,
        position contents.manga_staff_position NOT NULL DEFAULT 'other',
        notes TEXT,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (manga_id, person_id, position)
    )
    """, "DROP TABLE IF EXISTS contents.manga_staff CASCADE"
  end

  # ============================================================================
  # CONTENT RELATION TABLES
  # ============================================================================
  defp create_content_relation_tables do
    # Anime-Anime relationships
    execute """
    CREATE TABLE contents.anime_relations (
        id BIGSERIAL PRIMARY KEY,
        anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
        related_anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
        relation_type contents.content_relation NOT NULL,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        CONSTRAINT anime_relations_no_self CHECK (anime_id != related_anime_id)
    )
    """, "DROP TABLE IF EXISTS contents.anime_relations CASCADE"

    # Manga-Manga relationships
    execute """
    CREATE TABLE contents.manga_relations (
        id BIGSERIAL PRIMARY KEY,
        manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
        related_manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
        relation_type contents.content_relation NOT NULL,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        CONSTRAINT manga_relations_no_self CHECK (manga_id != related_manga_id)
    )
    """, "DROP TABLE IF EXISTS contents.manga_relations CASCADE"

    # Anime-Manga relationships
    execute """
    CREATE TABLE contents.anime_manga_relations (
        id BIGSERIAL PRIMARY KEY,
        anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
        manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
        relation_type contents.content_relation NOT NULL,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.anime_manga_relations CASCADE"
  end

  # ============================================================================
  # SCORE DISTRIBUTION TABLES
  # ============================================================================
  defp create_score_distribution_tables do
    # Anime score distributions
    execute """
    CREATE TABLE contents.anime_score_distributions (
        id BIGSERIAL PRIMARY KEY,
        anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
        score INTEGER NOT NULL CHECK (score >= 1 AND score <= 10),
        votes INTEGER DEFAULT 0 CHECK (votes >= 0),
        percentage NUMERIC(5,2) DEFAULT 0.0 CHECK (percentage >= 0 AND percentage <= 100),
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        UNIQUE (anime_id, score)
    )
    """, "DROP TABLE IF EXISTS contents.anime_score_distributions CASCADE"

    # Manga score distributions
    execute """
    CREATE TABLE contents.manga_score_distributions (
        id BIGSERIAL PRIMARY KEY,
        manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
        score INTEGER NOT NULL CHECK (score >= 1 AND score <= 10),
        votes INTEGER DEFAULT 0 CHECK (votes >= 0),
        percentage NUMERIC(5,2) DEFAULT 0.0 CHECK (percentage >= 0 AND percentage <= 100),
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        UNIQUE (manga_id, score)
    )
    """, "DROP TABLE IF EXISTS contents.manga_score_distributions CASCADE"

    # Episode score distributions
    execute """
    CREATE TABLE contents.episode_score_distributions (
        id BIGSERIAL PRIMARY KEY,
        episode_id BIGINT NOT NULL REFERENCES contents.episodes(id) ON DELETE CASCADE,
        score INTEGER NOT NULL CHECK (score >= 1 AND score <= 10),
        votes INTEGER DEFAULT 0 CHECK (votes >= 0),
        percentage NUMERIC(5,2) DEFAULT 0.0 CHECK (percentage >= 0 AND percentage <= 100),
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        UNIQUE (episode_id, score)
    )
    """, "DROP TABLE IF EXISTS contents.episode_score_distributions CASCADE"

    # Chapter score distributions
    execute """
    CREATE TABLE contents.chapter_score_distributions (
        id BIGSERIAL PRIMARY KEY,
        chapter_id BIGINT NOT NULL REFERENCES contents.chapters(id) ON DELETE CASCADE,
        score INTEGER NOT NULL CHECK (score >= 1 AND score <= 10),
        votes INTEGER DEFAULT 0 CHECK (votes >= 0),
        percentage NUMERIC(5,2) DEFAULT 0.0 CHECK (percentage >= 0 AND percentage <= 100),
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        UNIQUE (chapter_id, score)
    )
    """, "DROP TABLE IF EXISTS contents.chapter_score_distributions CASCADE"
  end

  # ============================================================================
  # PICTURE TABLES
  # ============================================================================
  defp create_picture_tables do
    # Anime pictures
    execute """
    CREATE TABLE contents.anime_pictures (
        id BIGSERIAL PRIMARY KEY,
        anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
        jpg_image_url VARCHAR(1000),
        jpg_small_image_url VARCHAR(1000),
        jpg_large_image_url VARCHAR(1000),
        webp_image_url VARCHAR(1000),
        webp_small_image_url VARCHAR(1000),
        webp_large_image_url VARCHAR(1000),
        is_primary BOOLEAN DEFAULT FALSE,
        display_order INTEGER DEFAULT 0,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.anime_pictures CASCADE"

    # Manga pictures
    execute """
    CREATE TABLE contents.manga_pictures (
        id BIGSERIAL PRIMARY KEY,
        manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
        jpg_image_url VARCHAR(1000),
        jpg_small_image_url VARCHAR(1000),
        jpg_large_image_url VARCHAR(1000),
        webp_image_url VARCHAR(1000),
        webp_small_image_url VARCHAR(1000),
        webp_large_image_url VARCHAR(1000),
        is_primary BOOLEAN DEFAULT FALSE,
        display_order INTEGER DEFAULT 0,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.manga_pictures CASCADE"

    # Character pictures
    execute """
    CREATE TABLE contents.character_pictures (
        id BIGSERIAL PRIMARY KEY,
        character_id BIGINT NOT NULL REFERENCES contents.characters(id) ON DELETE CASCADE,
        jpg_image_url VARCHAR(1000),
        jpg_small_image_url VARCHAR(1000),
        jpg_large_image_url VARCHAR(1000),
        webp_image_url VARCHAR(1000),
        webp_small_image_url VARCHAR(1000),
        webp_large_image_url VARCHAR(1000),
        is_primary BOOLEAN DEFAULT FALSE,
        display_order INTEGER DEFAULT 0,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.character_pictures CASCADE"

    # Person pictures
    execute """
    CREATE TABLE contents.person_pictures (
        id BIGSERIAL PRIMARY KEY,
        person_id BIGINT NOT NULL REFERENCES contents.people(id) ON DELETE CASCADE,
        jpg_image_url VARCHAR(1000),
        jpg_small_image_url VARCHAR(1000),
        jpg_large_image_url VARCHAR(1000),
        webp_image_url VARCHAR(1000),
        webp_small_image_url VARCHAR(1000),
        webp_large_image_url VARCHAR(1000),
        is_primary BOOLEAN DEFAULT FALSE,
        display_order INTEGER DEFAULT 0,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.person_pictures CASCADE"
  end

  # ============================================================================
  # HISTORY TABLES
  # ============================================================================
  defp create_history_tables do
    # Anime change history
    execute """
    CREATE TABLE contents.anime_history (
        id BIGSERIAL PRIMARY KEY,
        anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
        changed_fields JSONB NOT NULL,
        previous_values JSONB NOT NULL,
        new_values JSONB NOT NULL,
        change_source VARCHAR(50) NOT NULL,
        changed_by VARCHAR(255),
        change_reason TEXT,
        changed_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.anime_history CASCADE"

    # Manga change history
    execute """
    CREATE TABLE contents.manga_history (
        id BIGSERIAL PRIMARY KEY,
        manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
        changed_fields JSONB NOT NULL,
        previous_values JSONB NOT NULL,
        new_values JSONB NOT NULL,
        change_source VARCHAR(50) NOT NULL,
        changed_by VARCHAR(255),
        change_reason TEXT,
        changed_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.manga_history CASCADE"
  end

  # ============================================================================
  # SYNC TABLES
  # ============================================================================
  defp create_sync_tables do
    # Sync job runs
    execute """
    CREATE TABLE contents.sync_job_runs (
        id BIGSERIAL PRIMARY KEY,
        job_id VARCHAR(255) NOT NULL,
        source VARCHAR(50) NOT NULL,
        content_type VARCHAR(20) NOT NULL,
        status contents.sync_status DEFAULT 'pending' NOT NULL,
        priority INTEGER DEFAULT 0,
        started_at TIMESTAMP(0),
        completed_at TIMESTAMP(0),
        error_message TEXT,
        error_count INTEGER DEFAULT 0,
        records_processed INTEGER DEFAULT 0,
        records_created INTEGER DEFAULT 0,
        records_updated INTEGER DEFAULT 0,
        records_failed INTEGER DEFAULT 0,
        metadata JSONB DEFAULT '{}'::JSONB,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.sync_job_runs CASCADE"

    # Sync errors
    execute """
    CREATE TABLE contents.sync_errors (
        id BIGSERIAL PRIMARY KEY,
        sync_job_id BIGINT REFERENCES contents.sync_job_runs(id) ON DELETE SET NULL,
        source VARCHAR(50) NOT NULL,
        content_type VARCHAR(20) NOT NULL,
        external_id VARCHAR(100),
        error_type VARCHAR(100) NOT NULL,
        error_message TEXT NOT NULL,
        stack_trace TEXT,
        request_data JSONB,
        response_data JSONB,
        created_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS contents.sync_errors CASCADE"
  end

  # ============================================================================
  # ALL INDEXES
  # ============================================================================
  defp create_all_indexes do
    # External ID indexes
    execute "CREATE UNIQUE INDEX idx_anime_mal_id ON contents.anime (mal_id) WHERE mal_id IS NOT NULL AND deleted_at IS NULL"
    execute "CREATE UNIQUE INDEX idx_anime_anilist_id ON contents.anime (anilist_id) WHERE anilist_id IS NOT NULL AND deleted_at IS NULL"
    execute "CREATE UNIQUE INDEX idx_anime_kitsu_id ON contents.anime (kitsu_id) WHERE kitsu_id IS NOT NULL AND deleted_at IS NULL"

    execute "CREATE UNIQUE INDEX idx_manga_mal_id ON contents.manga (mal_id) WHERE mal_id IS NOT NULL AND deleted_at IS NULL"
    execute "CREATE UNIQUE INDEX idx_manga_anilist_id ON contents.manga (anilist_id) WHERE anilist_id IS NOT NULL AND deleted_at IS NULL"
    execute "CREATE UNIQUE INDEX idx_manga_kitsu_id ON contents.manga (kitsu_id) WHERE kitsu_id IS NOT NULL AND deleted_at IS NULL"

    execute "CREATE INDEX idx_episodes_mal_id ON contents.episodes (mal_id) WHERE mal_id IS NOT NULL"
    execute "CREATE INDEX idx_episodes_anilist_id ON contents.episodes (anilist_id) WHERE anilist_id IS NOT NULL"

    execute "CREATE INDEX idx_chapters_mal_id ON contents.chapters (mal_id) WHERE mal_id IS NOT NULL"
    execute "CREATE INDEX idx_chapters_anilist_id ON contents.chapters (anilist_id) WHERE anilist_id IS NOT NULL"

    execute "CREATE UNIQUE INDEX idx_people_mal_id ON contents.people (mal_id) WHERE mal_id IS NOT NULL AND deleted_at IS NULL"
    execute "CREATE INDEX idx_people_anilist_id ON contents.people (anilist_id) WHERE anilist_id IS NOT NULL"

    execute "CREATE UNIQUE INDEX idx_characters_mal_id ON contents.characters (mal_id) WHERE mal_id IS NOT NULL AND deleted_at IS NULL"
    execute "CREATE INDEX idx_characters_anilist_id ON contents.characters (anilist_id) WHERE anilist_id IS NOT NULL"

    execute "CREATE UNIQUE INDEX idx_studios_mal_id ON contents.studios (mal_id) WHERE mal_id IS NOT NULL AND deleted_at IS NULL"
    execute "CREATE INDEX idx_studios_anilist_id ON contents.studios (anilist_id) WHERE anilist_id IS NOT NULL"

    execute "CREATE UNIQUE INDEX idx_genres_mal_id ON contents.genres (mal_id)"
    execute "CREATE INDEX idx_genres_anilist_id ON contents.genres (anilist_id) WHERE anilist_id IS NOT NULL"

    execute "CREATE UNIQUE INDEX idx_demographics_mal_id ON contents.demographics (mal_id)"
    execute "CREATE INDEX idx_demographics_anilist_id ON contents.demographics (anilist_id) WHERE anilist_id IS NOT NULL"

    execute "CREATE UNIQUE INDEX idx_themes_mal_id ON contents.themes (mal_id)"
    execute "CREATE INDEX idx_themes_anilist_id ON contents.themes (anilist_id) WHERE anilist_id IS NOT NULL"

    execute "CREATE UNIQUE INDEX idx_magazines_mal_id ON contents.magazines (mal_id)"
    execute "CREATE UNIQUE INDEX idx_magazines_name_en ON contents.magazines (name_en)"

    # Full-text search indexes
    execute "CREATE INDEX idx_anime_search_vector ON contents.anime USING GIN (search_vector) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_search_vector ON contents.manga USING GIN (search_vector) WHERE deleted_at IS NULL"

    # Trigram indexes
    execute "CREATE INDEX idx_anime_title_en_trgm ON contents.anime USING GIN (title_en gin_trgm_ops) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_title_ja_trgm ON contents.anime USING GIN (title_ja gin_trgm_ops) WHERE title_ja IS NOT NULL AND deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_title_romaji_trgm ON contents.anime USING GIN (title_romaji gin_trgm_ops) WHERE title_romaji IS NOT NULL AND deleted_at IS NULL"

    execute "CREATE INDEX idx_manga_title_en_trgm ON contents.manga USING GIN (title_en gin_trgm_ops) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_title_ja_trgm ON contents.manga USING GIN (title_ja gin_trgm_ops) WHERE title_ja IS NOT NULL AND deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_title_romaji_trgm ON contents.manga USING GIN (title_romaji gin_trgm_ops) WHERE title_romaji IS NOT NULL AND deleted_at IS NULL"

    execute "CREATE INDEX idx_characters_name_en_trgm ON contents.characters USING GIN (name_en gin_trgm_ops) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_characters_name_ja_trgm ON contents.characters USING GIN (name_ja gin_trgm_ops) WHERE name_ja IS NOT NULL AND deleted_at IS NULL"
    execute "CREATE INDEX idx_people_name_en_trgm ON contents.people USING GIN (name_en gin_trgm_ops) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_people_name_ja_trgm ON contents.people USING GIN (name_ja gin_trgm_ops) WHERE name_ja IS NOT NULL AND deleted_at IS NULL"

    # Content classification indexes
    execute "CREATE INDEX idx_anime_type_status ON contents.anime (type, status) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_season_year_season ON contents.anime (season_year DESC, season) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_start_date ON contents.anime (start_date DESC) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_status ON contents.anime (status) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_rating ON contents.anime (rating) WHERE deleted_at IS NULL"

    execute "CREATE INDEX idx_manga_type_status ON contents.manga (type, status) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_published_from ON contents.manga (published_from DESC) WHERE deleted_at IS NULL"

    # Scoring and ranking indexes
    execute "CREATE INDEX idx_anime_mal_score ON contents.anime (mal_score DESC NULLS LAST) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_mal_popularity ON contents.anime (mal_popularity) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_mal_rank ON contents.anime (mal_rank) WHERE mal_rank IS NOT NULL AND deleted_at IS NULL"

    execute "CREATE INDEX idx_manga_mal_score ON contents.manga (mal_score DESC NULLS LAST) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_mal_popularity ON contents.manga (mal_popularity) WHERE deleted_at IS NULL"

    execute "CREATE INDEX idx_anime_internal_score ON contents.anime (internal_score DESC) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_internal_rank ON contents.anime (internal_rank) WHERE internal_rank IS NOT NULL AND deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_internal_popularity ON contents.anime (internal_popularity) WHERE internal_popularity IS NOT NULL AND deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_internal_trending ON contents.anime (internal_trending_score DESC) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_internal_recommendation ON contents.anime (internal_recommendation_score DESC) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_average_rating ON contents.anime (average_rating DESC) WHERE deleted_at IS NULL"

    execute "CREATE INDEX idx_manga_internal_score ON contents.manga (internal_score DESC) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_internal_trending ON contents.manga (internal_trending_score DESC) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_average_rating ON contents.manga (average_rating DESC) WHERE deleted_at IS NULL"

    # Engagement indexes
    execute "CREATE INDEX idx_anime_view_count ON contents.anime (view_count DESC) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_interaction_count ON contents.anime (interaction_count DESC) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_bookmark_count ON contents.anime (bookmark_count DESC) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_quality_score ON contents.anime (quality_score DESC) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_engagement_score ON contents.anime (engagement_score DESC) WHERE deleted_at IS NULL"

    execute "CREATE INDEX idx_manga_view_count ON contents.manga (view_count DESC) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_bookmark_count ON contents.manga (bookmark_count DESC) WHERE deleted_at IS NULL"

    # JSONB indexes
    execute "CREATE INDEX idx_anime_mood_tags ON contents.anime USING GIN (mood_tags jsonb_path_ops) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_content_warnings ON contents.anime USING GIN (content_warnings jsonb_path_ops) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_streaming_links ON contents.anime USING GIN (streaming_links jsonb_path_ops) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_external_links ON contents.anime USING GIN (external_links jsonb_path_ops) WHERE deleted_at IS NULL"

    execute "CREATE INDEX idx_manga_mood_tags ON contents.manga USING GIN (mood_tags jsonb_path_ops) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_content_warnings ON contents.manga USING GIN (content_warnings jsonb_path_ops) WHERE deleted_at IS NULL"

    execute "CREATE INDEX idx_characters_personality_tags ON contents.characters USING GIN (personality_tags jsonb_path_ops) WHERE deleted_at IS NULL"

    # Episode/Chapter indexes
    execute "CREATE UNIQUE INDEX idx_episodes_anime_episode ON contents.episodes (anime_id, episode_number) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_episodes_anime_id ON contents.episodes (anime_id) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_episodes_aired ON contents.episodes (aired DESC) WHERE deleted_at IS NULL"

    execute "CREATE UNIQUE INDEX idx_chapters_manga_chapter ON contents.chapters (manga_id, chapter_number) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_chapters_manga_id ON contents.chapters (manga_id) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_chapters_published ON contents.chapters (published DESC) WHERE deleted_at IS NULL"

    # Relationship table indexes
    execute "CREATE INDEX idx_anime_genres_genre ON contents.anime_genres (genre_id)"
    execute "CREATE INDEX idx_anime_demographics_demographic ON contents.anime_demographics (demographic_id)"
    execute "CREATE INDEX idx_anime_themes_theme ON contents.anime_themes (theme_id)"
    execute "CREATE INDEX idx_anime_sub_genres_sub_genre ON contents.anime_sub_genres (sub_genre_id)"

    execute "CREATE INDEX idx_manga_genres_genre ON contents.manga_genres (genre_id)"
    execute "CREATE INDEX idx_manga_demographics_demographic ON contents.manga_demographics (demographic_id)"
    execute "CREATE INDEX idx_manga_themes_theme ON contents.manga_themes (theme_id)"
    execute "CREATE INDEX idx_manga_sub_genres_sub_genre ON contents.manga_sub_genres (sub_genre_id)"

    execute "CREATE INDEX idx_anime_studios_studio ON contents.anime_studios (studio_id)"
    execute "CREATE INDEX idx_manga_studios_studio ON contents.manga_studios (studio_id)"
    execute "CREATE INDEX idx_manga_magazines_magazine ON contents.manga_magazines (magazine_id)"

    execute "CREATE INDEX idx_anime_characters_character ON contents.anime_characters (character_id)"
    execute "CREATE INDEX idx_manga_characters_character ON contents.manga_characters (character_id)"

    execute "CREATE INDEX idx_character_voice_actors_person ON contents.character_voice_actors (person_id)"
    execute "CREATE INDEX idx_character_voice_actors_anime ON contents.character_voice_actors (anime_id)"
    execute "CREATE INDEX idx_character_voice_actors_language ON contents.character_voice_actors (language)"

    execute "CREATE INDEX idx_anime_staff_person ON contents.anime_staff (person_id)"
    execute "CREATE INDEX idx_manga_staff_person ON contents.manga_staff (person_id)"

    # Content relation indexes
    execute "CREATE UNIQUE INDEX idx_anime_relations_unique ON contents.anime_relations (anime_id, related_anime_id, relation_type)"
    execute "CREATE INDEX idx_anime_relations_related ON contents.anime_relations (related_anime_id)"
    execute "CREATE INDEX idx_anime_relations_type ON contents.anime_relations (relation_type)"

    execute "CREATE UNIQUE INDEX idx_manga_relations_unique ON contents.manga_relations (manga_id, related_manga_id, relation_type)"
    execute "CREATE INDEX idx_manga_relations_related ON contents.manga_relations (related_manga_id)"

    execute "CREATE UNIQUE INDEX idx_anime_manga_relations_unique ON contents.anime_manga_relations (anime_id, manga_id, relation_type)"
    execute "CREATE INDEX idx_anime_manga_relations_anime ON contents.anime_manga_relations (anime_id)"
    execute "CREATE INDEX idx_anime_manga_relations_manga ON contents.anime_manga_relations (manga_id)"

    # Picture indexes
    execute "CREATE INDEX idx_anime_pictures_anime ON contents.anime_pictures (anime_id)"
    execute "CREATE INDEX idx_anime_pictures_primary ON contents.anime_pictures (anime_id) WHERE is_primary = TRUE"

    execute "CREATE INDEX idx_manga_pictures_manga ON contents.manga_pictures (manga_id)"
    execute "CREATE INDEX idx_manga_pictures_primary ON contents.manga_pictures (manga_id) WHERE is_primary = TRUE"

    execute "CREATE INDEX idx_character_pictures_character ON contents.character_pictures (character_id)"
    execute "CREATE INDEX idx_character_pictures_primary ON contents.character_pictures (character_id) WHERE is_primary = TRUE"

    execute "CREATE INDEX idx_person_pictures_person ON contents.person_pictures (person_id)"
    execute "CREATE INDEX idx_person_pictures_primary ON contents.person_pictures (person_id) WHERE is_primary = TRUE"

    # Score distribution indexes
    execute "CREATE INDEX idx_anime_score_dist_anime ON contents.anime_score_distributions (anime_id)"
    execute "CREATE INDEX idx_manga_score_dist_manga ON contents.manga_score_distributions (manga_id)"
    execute "CREATE INDEX idx_episode_score_dist_episode ON contents.episode_score_distributions (episode_id)"
    execute "CREATE INDEX idx_chapter_score_dist_chapter ON contents.chapter_score_distributions (chapter_id)"

    # History indexes
    execute "CREATE INDEX idx_anime_history_anime ON contents.anime_history (anime_id)"
    execute "CREATE INDEX idx_anime_history_changed_at ON contents.anime_history (changed_at DESC)"
    execute "CREATE INDEX idx_anime_history_source ON contents.anime_history (change_source)"

    execute "CREATE INDEX idx_manga_history_manga ON contents.manga_history (manga_id)"
    execute "CREATE INDEX idx_manga_history_changed_at ON contents.manga_history (changed_at DESC)"

    # Sync indexes
    execute "CREATE UNIQUE INDEX idx_sync_job_runs_job_id ON contents.sync_job_runs (job_id)"
    execute "CREATE INDEX idx_sync_job_runs_status ON contents.sync_job_runs (status)"
    execute "CREATE INDEX idx_sync_job_runs_source_type ON contents.sync_job_runs (source, content_type)"
    execute "CREATE INDEX idx_sync_job_runs_started_at ON contents.sync_job_runs (started_at DESC)"

    execute "CREATE INDEX idx_sync_errors_job ON contents.sync_errors (sync_job_id)"
    execute "CREATE INDEX idx_sync_errors_source_type ON contents.sync_errors (source, content_type)"
    execute "CREATE INDEX idx_sync_errors_created_at ON contents.sync_errors (created_at DESC)"

    # System indexes
    execute "CREATE INDEX idx_anime_enriched ON contents.anime (enriched) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_sync_status ON contents.anime (sync_status) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_last_synced ON contents.anime (last_synced_at) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_deleted ON contents.anime (deleted_at) WHERE deleted_at IS NOT NULL"

    execute "CREATE INDEX idx_manga_enriched ON contents.manga (enriched) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_sync_status ON contents.manga (sync_status) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_deleted ON contents.manga (deleted_at) WHERE deleted_at IS NOT NULL"

    execute "CREATE INDEX idx_people_enriched ON contents.people (enriched) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_characters_enriched ON contents.characters (enriched) WHERE deleted_at IS NULL"

    # Composite indexes
    execute "CREATE INDEX idx_anime_browse ON contents.anime (type, status, mal_score DESC NULLS LAST) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_seasonal ON contents.anime (season_year DESC, season, mal_score DESC NULLS LAST) WHERE deleted_at IS NULL AND season IS NOT NULL"
    execute "CREATE INDEX idx_anime_airing ON contents.anime (mal_score DESC NULLS LAST) WHERE status = 'airing' AND deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_top ON contents.anime (mal_rank) WHERE mal_rank IS NOT NULL AND deleted_at IS NULL"
    execute "CREATE INDEX idx_anime_list_cover ON contents.anime (id, title_en, cover_image_url, type, status, mal_score, episodes) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_manga_browse ON contents.manga (type, status, mal_score DESC NULLS LAST) WHERE deleted_at IS NULL"
  end

  # ============================================================================
  # FUNCTIONS
  # ============================================================================
  defp create_functions do
    # Search vector update for anime
    execute """
    CREATE OR REPLACE FUNCTION contents.update_anime_search_vector() RETURNS TRIGGER AS $$
    BEGIN
        NEW.search_vector :=
            setweight(to_tsvector('english', COALESCE(NEW.title_en, '')), 'A') ||
            setweight(to_tsvector('english', COALESCE(NEW.synopsis_en, '')), 'C') ||
            setweight(to_tsvector('simple', COALESCE(NEW.title_ja, '')), 'A') ||
            setweight(to_tsvector('simple', COALESCE(NEW.synopsis_ja, '')), 'C') ||
            setweight(to_tsvector('english', COALESCE(NEW.title_romaji, '')), 'B') ||
            setweight(to_tsvector('english', COALESCE(array_to_string(NEW.title_synonyms, ' '), '')), 'B');
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS contents.update_anime_search_vector()"

    # Search vector update for manga
    execute """
    CREATE OR REPLACE FUNCTION contents.update_manga_search_vector() RETURNS TRIGGER AS $$
    BEGIN
        NEW.search_vector :=
            setweight(to_tsvector('english', COALESCE(NEW.title_en, '')), 'A') ||
            setweight(to_tsvector('english', COALESCE(NEW.synopsis_en, '')), 'C') ||
            setweight(to_tsvector('simple', COALESCE(NEW.title_ja, '')), 'A') ||
            setweight(to_tsvector('simple', COALESCE(NEW.synopsis_ja, '')), 'C') ||
            setweight(to_tsvector('english', COALESCE(NEW.title_romaji, '')), 'B') ||
            setweight(to_tsvector('english', COALESCE(array_to_string(NEW.title_synonyms, ' '), '')), 'B');
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS contents.update_manga_search_vector()"

    # Updated at trigger function
    execute """
    CREATE OR REPLACE FUNCTION contents.update_updated_at() RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS contents.update_updated_at()"

    # Soft delete helper
    execute """
    CREATE OR REPLACE FUNCTION contents.soft_delete() RETURNS TRIGGER AS $$
    BEGIN
        NEW.deleted_at = NOW();
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS contents.soft_delete()"

    # Anime history tracking
    execute """
    CREATE OR REPLACE FUNCTION contents.track_anime_changes() RETURNS TRIGGER AS $$
    DECLARE
        changed_fields JSONB := '[]'::JSONB;
        prev_values JSONB := '{}'::JSONB;
        new_values JSONB := '{}'::JSONB;
    BEGIN
        IF OLD.title_en IS DISTINCT FROM NEW.title_en THEN
            changed_fields := changed_fields || '"title_en"'::JSONB;
            prev_values := prev_values || jsonb_build_object('title_en', OLD.title_en);
            new_values := new_values || jsonb_build_object('title_en', NEW.title_en);
        END IF;

        IF OLD.synopsis_en IS DISTINCT FROM NEW.synopsis_en THEN
            changed_fields := changed_fields || '"synopsis_en"'::JSONB;
            prev_values := prev_values || jsonb_build_object('synopsis_en', OLD.synopsis_en);
            new_values := new_values || jsonb_build_object('synopsis_en', NEW.synopsis_en);
        END IF;

        IF OLD.mal_score IS DISTINCT FROM NEW.mal_score THEN
            changed_fields := changed_fields || '"mal_score"'::JSONB;
            prev_values := prev_values || jsonb_build_object('mal_score', OLD.mal_score);
            new_values := new_values || jsonb_build_object('mal_score', NEW.mal_score);
        END IF;

        IF OLD.status IS DISTINCT FROM NEW.status THEN
            changed_fields := changed_fields || '"status"'::JSONB;
            prev_values := prev_values || jsonb_build_object('status', OLD.status);
            new_values := new_values || jsonb_build_object('status', NEW.status);
        END IF;

        IF OLD.episodes IS DISTINCT FROM NEW.episodes THEN
            changed_fields := changed_fields || '"episodes"'::JSONB;
            prev_values := prev_values || jsonb_build_object('episodes', OLD.episodes);
            new_values := new_values || jsonb_build_object('episodes', NEW.episodes);
        END IF;

        IF jsonb_array_length(changed_fields) > 0 THEN
            INSERT INTO contents.anime_history (anime_id, changed_fields, previous_values, new_values, change_source)
            VALUES (NEW.id, changed_fields, prev_values, new_values, COALESCE(current_setting('app.change_source', true), 'unknown'));
        END IF;

        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS contents.track_anime_changes()"

    # Manga history tracking
    execute """
    CREATE OR REPLACE FUNCTION contents.track_manga_changes() RETURNS TRIGGER AS $$
    DECLARE
        changed_fields JSONB := '[]'::JSONB;
        prev_values JSONB := '{}'::JSONB;
        new_values JSONB := '{}'::JSONB;
    BEGIN
        IF OLD.title_en IS DISTINCT FROM NEW.title_en THEN
            changed_fields := changed_fields || '"title_en"'::JSONB;
            prev_values := prev_values || jsonb_build_object('title_en', OLD.title_en);
            new_values := new_values || jsonb_build_object('title_en', NEW.title_en);
        END IF;

        IF OLD.synopsis_en IS DISTINCT FROM NEW.synopsis_en THEN
            changed_fields := changed_fields || '"synopsis_en"'::JSONB;
            prev_values := prev_values || jsonb_build_object('synopsis_en', OLD.synopsis_en);
            new_values := new_values || jsonb_build_object('synopsis_en', NEW.synopsis_en);
        END IF;

        IF OLD.mal_score IS DISTINCT FROM NEW.mal_score THEN
            changed_fields := changed_fields || '"mal_score"'::JSONB;
            prev_values := prev_values || jsonb_build_object('mal_score', OLD.mal_score);
            new_values := new_values || jsonb_build_object('mal_score', NEW.mal_score);
        END IF;

        IF OLD.status IS DISTINCT FROM NEW.status THEN
            changed_fields := changed_fields || '"status"'::JSONB;
            prev_values := prev_values || jsonb_build_object('status', OLD.status);
            new_values := new_values || jsonb_build_object('status', NEW.status);
        END IF;

        IF OLD.chapters IS DISTINCT FROM NEW.chapters THEN
            changed_fields := changed_fields || '"chapters"'::JSONB;
            prev_values := prev_values || jsonb_build_object('chapters', OLD.chapters);
            new_values := new_values || jsonb_build_object('chapters', NEW.chapters);
        END IF;

        IF jsonb_array_length(changed_fields) > 0 THEN
            INSERT INTO contents.manga_history (manga_id, changed_fields, previous_values, new_values, change_source)
            VALUES (NEW.id, changed_fields, prev_values, new_values, COALESCE(current_setting('app.change_source', true), 'unknown'));
        END IF;

        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS contents.track_manga_changes()"
  end

  # ============================================================================
  # TRIGGERS
  # ============================================================================
  defp create_triggers do
    # Search vector triggers
    execute """
    CREATE TRIGGER anime_search_vector_update_trigger
        BEFORE INSERT OR UPDATE ON contents.anime
        FOR EACH ROW EXECUTE FUNCTION contents.update_anime_search_vector()
    """

    execute """
    CREATE TRIGGER manga_search_vector_update_trigger
        BEFORE INSERT OR UPDATE ON contents.manga
        FOR EACH ROW EXECUTE FUNCTION contents.update_manga_search_vector()
    """

    # Updated at triggers
    execute """
    CREATE TRIGGER anime_updated_at_trigger
        BEFORE UPDATE ON contents.anime
        FOR EACH ROW EXECUTE FUNCTION contents.update_updated_at()
    """

    execute """
    CREATE TRIGGER manga_updated_at_trigger
        BEFORE UPDATE ON contents.manga
        FOR EACH ROW EXECUTE FUNCTION contents.update_updated_at()
    """

    execute """
    CREATE TRIGGER episodes_updated_at_trigger
        BEFORE UPDATE ON contents.episodes
        FOR EACH ROW EXECUTE FUNCTION contents.update_updated_at()
    """

    execute """
    CREATE TRIGGER chapters_updated_at_trigger
        BEFORE UPDATE ON contents.chapters
        FOR EACH ROW EXECUTE FUNCTION contents.update_updated_at()
    """

    execute """
    CREATE TRIGGER people_updated_at_trigger
        BEFORE UPDATE ON contents.people
        FOR EACH ROW EXECUTE FUNCTION contents.update_updated_at()
    """

    execute """
    CREATE TRIGGER characters_updated_at_trigger
        BEFORE UPDATE ON contents.characters
        FOR EACH ROW EXECUTE FUNCTION contents.update_updated_at()
    """

    execute """
    CREATE TRIGGER studios_updated_at_trigger
        BEFORE UPDATE ON contents.studios
        FOR EACH ROW EXECUTE FUNCTION contents.update_updated_at()
    """

    execute """
    CREATE TRIGGER magazines_updated_at_trigger
        BEFORE UPDATE ON contents.magazines
        FOR EACH ROW EXECUTE FUNCTION contents.update_updated_at()
    """

    execute """
    CREATE TRIGGER anime_pictures_updated_at_trigger
        BEFORE UPDATE ON contents.anime_pictures
        FOR EACH ROW EXECUTE FUNCTION contents.update_updated_at()
    """

    execute """
    CREATE TRIGGER manga_pictures_updated_at_trigger
        BEFORE UPDATE ON contents.manga_pictures
        FOR EACH ROW EXECUTE FUNCTION contents.update_updated_at()
    """

    execute """
    CREATE TRIGGER character_pictures_updated_at_trigger
        BEFORE UPDATE ON contents.character_pictures
        FOR EACH ROW EXECUTE FUNCTION contents.update_updated_at()
    """

    execute """
    CREATE TRIGGER person_pictures_updated_at_trigger
        BEFORE UPDATE ON contents.person_pictures
        FOR EACH ROW EXECUTE FUNCTION contents.update_updated_at()
    """

    execute """
    CREATE TRIGGER anime_score_distributions_updated_at_trigger
        BEFORE UPDATE ON contents.anime_score_distributions
        FOR EACH ROW EXECUTE FUNCTION contents.update_updated_at()
    """

    execute """
    CREATE TRIGGER manga_score_distributions_updated_at_trigger
        BEFORE UPDATE ON contents.manga_score_distributions
        FOR EACH ROW EXECUTE FUNCTION contents.update_updated_at()
    """

    execute """
    CREATE TRIGGER sync_job_runs_updated_at_trigger
        BEFORE UPDATE ON contents.sync_job_runs
        FOR EACH ROW EXECUTE FUNCTION contents.update_updated_at()
    """

    # History tracking triggers
    execute """
    CREATE TRIGGER anime_history_trigger
        AFTER UPDATE ON contents.anime
        FOR EACH ROW
        WHEN (OLD.* IS DISTINCT FROM NEW.*)
        EXECUTE FUNCTION contents.track_anime_changes()
    """

    execute """
    CREATE TRIGGER manga_history_trigger
        AFTER UPDATE ON contents.manga
        FOR EACH ROW
        WHEN (OLD.* IS DISTINCT FROM NEW.*)
        EXECUTE FUNCTION contents.track_manga_changes()
    """
  end

  # ============================================================================
  # MATERIALIZED VIEWS
  # ============================================================================
  defp create_materialized_views do
    # Top anime
    execute """
    CREATE MATERIALIZED VIEW contents.mv_top_anime AS
    SELECT
        a.id,
        a.mal_id,
        a.title_en,
        a.title_ja,
        a.cover_image_url,
        a.type,
        a.status,
        a.episodes,
        a.mal_score,
        a.mal_rank,
        a.mal_popularity,
        a.mal_members,
        a.internal_score,
        a.average_rating,
        a.rating_count,
        ARRAY_AGG(DISTINCT g.name_en) FILTER (WHERE g.name_en IS NOT NULL) AS genres
    FROM contents.anime a
    LEFT JOIN contents.anime_genres ag ON a.id = ag.anime_id
    LEFT JOIN contents.genres g ON ag.genre_id = g.id
    WHERE a.deleted_at IS NULL
        AND a.mal_rank IS NOT NULL
    GROUP BY a.id
    ORDER BY a.mal_rank
    LIMIT 1000
    """, "DROP MATERIALIZED VIEW IF EXISTS contents.mv_top_anime"

    execute "CREATE UNIQUE INDEX idx_mv_top_anime_id ON contents.mv_top_anime (id)"
    execute "CREATE INDEX idx_mv_top_anime_rank ON contents.mv_top_anime (mal_rank)"

    # Currently airing anime
    execute """
    CREATE MATERIALIZED VIEW contents.mv_airing_anime AS
    SELECT
        a.id,
        a.mal_id,
        a.title_en,
        a.title_ja,
        a.cover_image_url,
        a.type,
        a.episodes,
        a.mal_score,
        a.broadcast_day,
        a.broadcast_time,
        a.season,
        a.season_year,
        ARRAY_AGG(DISTINCT g.name_en) FILTER (WHERE g.name_en IS NOT NULL) AS genres,
        ARRAY_AGG(DISTINCT s.name_en) FILTER (WHERE s.name_en IS NOT NULL) AS studios
    FROM contents.anime a
    LEFT JOIN contents.anime_genres ag ON a.id = ag.anime_id
    LEFT JOIN contents.genres g ON ag.genre_id = g.id
    LEFT JOIN contents.anime_studios ast ON a.id = ast.anime_id AND ast.role = 'main_studio'
    LEFT JOIN contents.studios s ON ast.studio_id = s.id
    WHERE a.status = 'airing'
        AND a.deleted_at IS NULL
    GROUP BY a.id
    ORDER BY a.mal_score DESC NULLS LAST
    """, "DROP MATERIALIZED VIEW IF EXISTS contents.mv_airing_anime"

    execute "CREATE UNIQUE INDEX idx_mv_airing_anime_id ON contents.mv_airing_anime (id)"
    execute "CREATE INDEX idx_mv_airing_anime_day ON contents.mv_airing_anime (broadcast_day)"

    # Top manga
    execute """
    CREATE MATERIALIZED VIEW contents.mv_top_manga AS
    SELECT
        m.id,
        m.mal_id,
        m.title_en,
        m.title_ja,
        m.cover_image_url,
        m.type,
        m.status,
        m.chapters,
        m.volumes,
        m.mal_score,
        m.mal_rank,
        m.mal_popularity,
        ARRAY_AGG(DISTINCT g.name_en) FILTER (WHERE g.name_en IS NOT NULL) AS genres
    FROM contents.manga m
    LEFT JOIN contents.manga_genres mg ON m.id = mg.manga_id
    LEFT JOIN contents.genres g ON mg.genre_id = g.id
    WHERE m.deleted_at IS NULL
        AND m.mal_rank IS NOT NULL
    GROUP BY m.id
    ORDER BY m.mal_rank
    LIMIT 1000
    """, "DROP MATERIALIZED VIEW IF EXISTS contents.mv_top_manga"

    execute "CREATE UNIQUE INDEX idx_mv_top_manga_id ON contents.mv_top_manga (id)"
    execute "CREATE INDEX idx_mv_top_manga_rank ON contents.mv_top_manga (mal_rank)"

    # Genre statistics
    execute """
    CREATE MATERIALIZED VIEW contents.mv_genre_stats AS
    SELECT
        g.id,
        g.name_en,
        g.category,
        COUNT(DISTINCT ag.anime_id) AS anime_count,
        COUNT(DISTINCT mg.manga_id) AS manga_count,
        AVG(a.mal_score) FILTER (WHERE a.mal_score IS NOT NULL) AS avg_anime_score,
        AVG(m.mal_score) FILTER (WHERE m.mal_score IS NOT NULL) AS avg_manga_score
    FROM contents.genres g
    LEFT JOIN contents.anime_genres ag ON g.id = ag.genre_id
    LEFT JOIN contents.anime a ON ag.anime_id = a.id AND a.deleted_at IS NULL
    LEFT JOIN contents.manga_genres mg ON g.id = mg.genre_id
    LEFT JOIN contents.manga m ON mg.manga_id = m.id AND m.deleted_at IS NULL
    GROUP BY g.id, g.name_en, g.category
    ORDER BY (COUNT(DISTINCT ag.anime_id) + COUNT(DISTINCT mg.manga_id)) DESC
    """, "DROP MATERIALIZED VIEW IF EXISTS contents.mv_genre_stats"

    execute "CREATE UNIQUE INDEX idx_mv_genre_stats_id ON contents.mv_genre_stats (id)"
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================
  defp create_helper_functions do
    # Refresh all materialized views
    execute """
    CREATE OR REPLACE FUNCTION contents.refresh_all_materialized_views() RETURNS void AS $$
    BEGIN
        REFRESH MATERIALIZED VIEW CONCURRENTLY contents.mv_top_anime;
        REFRESH MATERIALIZED VIEW CONCURRENTLY contents.mv_airing_anime;
        REFRESH MATERIALIZED VIEW CONCURRENTLY contents.mv_top_manga;
        REFRESH MATERIALIZED VIEW CONCURRENTLY contents.mv_genre_stats;
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS contents.refresh_all_materialized_views()"

    # Search anime function
    execute """
    CREATE OR REPLACE FUNCTION contents.search_anime(
        search_query TEXT,
        limit_count INTEGER DEFAULT 20,
        offset_count INTEGER DEFAULT 0
    ) RETURNS TABLE (
        id BIGINT,
        title_en VARCHAR(500),
        title_ja VARCHAR(500),
        cover_image_url VARCHAR(1000),
        type contents.anime_type,
        status contents.anime_status,
        mal_score NUMERIC(4,2),
        relevance REAL
    ) AS $$
    BEGIN
        RETURN QUERY
        SELECT
            a.id,
            a.title_en,
            a.title_ja,
            a.cover_image_url,
            a.type,
            a.status,
            a.mal_score,
            GREATEST(
                ts_rank(a.search_vector, websearch_to_tsquery('english', search_query)),
                similarity(a.title_en, search_query),
                COALESCE(similarity(a.title_romaji, search_query), 0)
            ) AS relevance
        FROM contents.anime a
        WHERE a.deleted_at IS NULL
            AND (
                a.search_vector @@ websearch_to_tsquery('english', search_query)
                OR a.title_en % search_query
                OR a.title_romaji % search_query
                OR a.title_ja % search_query
            )
        ORDER BY relevance DESC, a.mal_popularity NULLS LAST
        LIMIT limit_count
        OFFSET offset_count;
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS contents.search_anime(TEXT, INTEGER, INTEGER)"

    # Search manga function
    execute """
    CREATE OR REPLACE FUNCTION contents.search_manga(
        search_query TEXT,
        limit_count INTEGER DEFAULT 20,
        offset_count INTEGER DEFAULT 0
    ) RETURNS TABLE (
        id BIGINT,
        title_en VARCHAR(500),
        title_ja VARCHAR(500),
        cover_image_url VARCHAR(1000),
        type contents.manga_type,
        status contents.manga_status,
        mal_score NUMERIC(4,2),
        relevance REAL
    ) AS $$
    BEGIN
        RETURN QUERY
        SELECT
            m.id,
            m.title_en,
            m.title_ja,
            m.cover_image_url,
            m.type,
            m.status,
            m.mal_score,
            GREATEST(
                ts_rank(m.search_vector, websearch_to_tsquery('english', search_query)),
                similarity(m.title_en, search_query),
                COALESCE(similarity(m.title_romaji, search_query), 0)
            ) AS relevance
        FROM contents.manga m
        WHERE m.deleted_at IS NULL
            AND (
                m.search_vector @@ websearch_to_tsquery('english', search_query)
                OR m.title_en % search_query
                OR m.title_romaji % search_query
                OR m.title_ja % search_query
            )
        ORDER BY relevance DESC, m.mal_popularity NULLS LAST
        LIMIT limit_count
        OFFSET offset_count;
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS contents.search_manga(TEXT, INTEGER, INTEGER)"

    # Get anime with all relations
    execute """
    CREATE OR REPLACE FUNCTION contents.get_anime_full(anime_id_param BIGINT)
    RETURNS JSON AS $$
    DECLARE
        result JSON;
    BEGIN
        SELECT json_build_object(
            'anime', row_to_json(a.*),
            'genres', (
                SELECT COALESCE(json_agg(json_build_object('id', g.id, 'name', g.name_en)), '[]'::json)
                FROM contents.anime_genres ag
                JOIN contents.genres g ON ag.genre_id = g.id
                WHERE ag.anime_id = a.id
            ),
            'themes', (
                SELECT COALESCE(json_agg(json_build_object('id', t.id, 'name', t.name_en)), '[]'::json)
                FROM contents.anime_themes at
                JOIN contents.themes t ON at.theme_id = t.id
                WHERE at.anime_id = a.id
            ),
            'studios', (
                SELECT COALESCE(json_agg(json_build_object('id', s.id, 'name', s.name_en, 'role', ast.role)), '[]'::json)
                FROM contents.anime_studios ast
                JOIN contents.studios s ON ast.studio_id = s.id
                WHERE ast.anime_id = a.id
            ),
            'characters', (
                SELECT COALESCE(json_agg(json_build_object(
                    'id', c.id,
                    'name', c.name_en,
                    'image', c.image_url,
                    'role', ac.role
                ) ORDER BY ac.role, c.favorites_count DESC), '[]'::json)
                FROM contents.anime_characters ac
                JOIN contents.characters c ON ac.character_id = c.id
                WHERE ac.anime_id = a.id AND c.deleted_at IS NULL
                LIMIT 20
            ),
            'relations', (
                SELECT COALESCE(json_agg(json_build_object(
                    'id', ra.id,
                    'title', ra.title_en,
                    'type', ra.type,
                    'relation', ar.relation_type
                )), '[]'::json)
                FROM contents.anime_relations ar
                JOIN contents.anime ra ON ar.related_anime_id = ra.id
                WHERE ar.anime_id = a.id AND ra.deleted_at IS NULL
            )
        ) INTO result
        FROM contents.anime a
        WHERE a.id = anime_id_param AND a.deleted_at IS NULL;

        RETURN result;
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS contents.get_anime_full(BIGINT)"

    # Get manga with all relations
    execute """
    CREATE OR REPLACE FUNCTION contents.get_manga_full(manga_id_param BIGINT)
    RETURNS JSON AS $$
    DECLARE
        result JSON;
    BEGIN
        SELECT json_build_object(
            'manga', row_to_json(m.*),
            'genres', (
                SELECT COALESCE(json_agg(json_build_object('id', g.id, 'name', g.name_en)), '[]'::json)
                FROM contents.manga_genres mg
                JOIN contents.genres g ON mg.genre_id = g.id
                WHERE mg.manga_id = m.id
            ),
            'themes', (
                SELECT COALESCE(json_agg(json_build_object('id', t.id, 'name', t.name_en)), '[]'::json)
                FROM contents.manga_themes mt
                JOIN contents.themes t ON mt.theme_id = t.id
                WHERE mt.manga_id = m.id
            ),
            'authors', (
                SELECT COALESCE(json_agg(json_build_object(
                    'id', p.id,
                    'name', p.name_en,
                    'position', ms.position
                )), '[]'::json)
                FROM contents.manga_staff ms
                JOIN contents.people p ON ms.person_id = p.id
                WHERE ms.manga_id = m.id AND p.deleted_at IS NULL
            ),
            'characters', (
                SELECT COALESCE(json_agg(json_build_object(
                    'id', c.id,
                    'name', c.name_en,
                    'image', c.image_url,
                    'role', mc.role
                ) ORDER BY mc.role, c.favorites_count DESC), '[]'::json)
                FROM contents.manga_characters mc
                JOIN contents.characters c ON mc.character_id = c.id
                WHERE mc.manga_id = m.id AND c.deleted_at IS NULL
                LIMIT 20
            ),
            'relations', (
                SELECT COALESCE(json_agg(json_build_object(
                    'id', rm.id,
                    'title', rm.title_en,
                    'type', rm.type,
                    'relation', mr.relation_type
                )), '[]'::json)
                FROM contents.manga_relations mr
                JOIN contents.manga rm ON mr.related_manga_id = rm.id
                WHERE mr.manga_id = m.id AND rm.deleted_at IS NULL
            )
        ) INTO result
        FROM contents.manga m
        WHERE m.id = manga_id_param AND m.deleted_at IS NULL;

        RETURN result;
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS contents.get_manga_full(BIGINT)"
  end

  # ============================================================================
  # COMMENTS
  # ============================================================================
  defp create_comments do
    execute "COMMENT ON TABLE contents.anime IS 'Core anime content table with full metadata, scores, and tracking'"
    execute "COMMENT ON TABLE contents.manga IS 'Core manga content table with full metadata, scores, and tracking'"
    execute "COMMENT ON TABLE contents.episodes IS 'Individual anime episodes with metadata and ratings'"
    execute "COMMENT ON TABLE contents.chapters IS 'Individual manga chapters with metadata and ratings'"
    execute "COMMENT ON TABLE contents.people IS 'Voice actors, directors, authors, and other industry people'"
    execute "COMMENT ON TABLE contents.characters IS 'Fictional characters appearing in anime/manga'"
    execute "COMMENT ON TABLE contents.studios IS 'Animation studios, production companies, and publishers'"
    execute "COMMENT ON TABLE contents.genres IS 'Content genres (Action, Comedy, Drama, etc.)'"
    execute "COMMENT ON TABLE contents.demographics IS 'Target demographic categories (Shounen, Seinen, etc.)'"
    execute "COMMENT ON TABLE contents.themes IS 'Content themes (Isekai, Time Travel, etc.)'"
    execute "COMMENT ON TABLE contents.anime_history IS 'Audit trail for anime content changes'"
    execute "COMMENT ON TABLE contents.manga_history IS 'Audit trail for manga content changes'"
    execute "COMMENT ON TABLE contents.sync_job_runs IS 'External API synchronization job tracking'"

    execute "COMMENT ON TYPE contents.anime_type IS 'Classification of anime format (TV, Movie, OVA, etc.)'"
    execute "COMMENT ON TYPE contents.anime_status IS 'Current airing status of anime'"
    execute "COMMENT ON TYPE contents.manga_type IS 'Classification of manga format (Manga, Manhwa, Light Novel, etc.)'"
    execute "COMMENT ON TYPE contents.manga_status IS 'Current publication status of manga'"
    execute "COMMENT ON TYPE contents.content_relation IS 'Types of relationships between content (Sequel, Prequel, etc.)'"

    execute "COMMENT ON FUNCTION contents.search_anime IS 'Combined full-text and fuzzy search for anime titles'"
    execute "COMMENT ON FUNCTION contents.search_manga IS 'Combined full-text and fuzzy search for manga titles'"
    execute "COMMENT ON FUNCTION contents.get_anime_full IS 'Retrieves complete anime data with all relations as JSON'"
    execute "COMMENT ON FUNCTION contents.get_manga_full IS 'Retrieves complete manga data with all relations as JSON'"
    execute "COMMENT ON FUNCTION contents.refresh_all_materialized_views IS 'Refreshes all materialized views concurrently'"
  end
end