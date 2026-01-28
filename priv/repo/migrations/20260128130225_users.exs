defmodule Yunaos.Repo.Migrations.Users do
  use Ecto.Migration

  def change do
    # ============================================================================
    # SCHEMA CREATION
    # ============================================================================
    execute "CREATE SCHEMA IF NOT EXISTS users", "DROP SCHEMA IF EXISTS users CASCADE"

    # ============================================================================
    # EXTENSIONS
    # ============================================================================
    execute "CREATE EXTENSION IF NOT EXISTS citext", "DROP EXTENSION IF EXISTS citext"
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"", "DROP EXTENSION IF EXISTS \"uuid-ossp\""

    # ============================================================================
    # ENUM TYPE DEFINITIONS
    # ============================================================================
    create_enum_types()

    # ============================================================================
    # CORE USER TABLES
    # ============================================================================
    create_users_table()
    create_user_tokens_table()
    create_user_identities_table()
    create_user_settings_table()

    # ============================================================================
    # LIST MANAGEMENT TABLES
    # ============================================================================
    create_user_anime_lists_table()
    create_user_manga_lists_table()
    create_user_episode_progress_table()
    create_user_chapter_progress_table()
    create_user_custom_lists_table()

    # ============================================================================
    # FAVORITES TABLES
    # ============================================================================
    create_favorites_tables()

    # ============================================================================
    # SOCIAL FEATURES
    # ============================================================================
    create_user_follows_table()
    create_user_blocks_table()

    # ============================================================================
    # REVIEWS
    # ============================================================================
    create_review_tables()

    # ============================================================================
    # CHAT SYSTEM
    # ============================================================================
    create_chat_tables()

    # ============================================================================
    # NOTIFICATIONS
    # ============================================================================
    create_notifications_table()

    # ============================================================================
    # ACTIVITY FEED
    # ============================================================================
    create_user_activities_table()

    # ============================================================================
    # REPORTS & MODERATION
    # ============================================================================
    create_moderation_tables()

    # ============================================================================
    # USER HISTORY & AUDIT
    # ============================================================================
    create_history_tables()

    # ============================================================================
    # IMPORT/EXPORT
    # ============================================================================
    create_import_tables()

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
    # VIEWS
    # ============================================================================
    create_views()

    # ============================================================================
    # COMMENTS
    # ============================================================================
    create_comments()
  end

  # ============================================================================
  # ENUM TYPES
  # ============================================================================
  defp create_enum_types do
    # User account status
    execute """
    CREATE TYPE users.user_status AS ENUM (
        'active', 'inactive', 'suspended', 'banned', 'deleted'
    )
    """, "DROP TYPE IF EXISTS users.user_status"

    # User role/permission level
    execute """
    CREATE TYPE users.user_role AS ENUM (
        'user', 'moderator', 'admin', 'super_admin'
    )
    """, "DROP TYPE IF EXISTS users.user_role"

    # Anime list status
    execute """
    CREATE TYPE users.anime_list_status AS ENUM (
        'watching', 'completed', 'on_hold', 'dropped', 'plan_to_watch'
    )
    """, "DROP TYPE IF EXISTS users.anime_list_status"

    # Manga list status
    execute """
    CREATE TYPE users.manga_list_status AS ENUM (
        'reading', 'completed', 'on_hold', 'dropped', 'plan_to_read'
    )
    """, "DROP TYPE IF EXISTS users.manga_list_status"

    # Follow status
    execute """
    CREATE TYPE users.follow_status AS ENUM (
        'pending', 'accepted', 'blocked'
    )
    """, "DROP TYPE IF EXISTS users.follow_status"

    # Review status
    execute """
    CREATE TYPE users.review_status AS ENUM (
        'draft', 'published', 'hidden', 'flagged', 'removed'
    )
    """, "DROP TYPE IF EXISTS users.review_status"

    # Notification type
    execute """
    CREATE TYPE users.notification_type AS ENUM (
        'follow_request', 'follow_accepted', 'new_follower', 'list_update',
        'review_like', 'review_comment', 'mention', 'system',
        'recommendation', 'new_episode', 'new_chapter'
    )
    """, "DROP TYPE IF EXISTS users.notification_type"

    # Report type
    execute """
    CREATE TYPE users.report_type AS ENUM (
        'spam', 'harassment', 'inappropriate_content', 'spoiler',
        'misinformation', 'copyright', 'other'
    )
    """, "DROP TYPE IF EXISTS users.report_type"

    # Report status
    execute """
    CREATE TYPE users.report_status AS ENUM (
        'pending', 'reviewing', 'resolved', 'dismissed'
    )
    """, "DROP TYPE IF EXISTS users.report_status"

    # Chat room type
    execute """
    CREATE TYPE users.chat_room_type AS ENUM (
        'anime', 'manga', 'episode', 'chapter', 'general', 'private'
    )
    """, "DROP TYPE IF EXISTS users.chat_room_type"

    # Chat participant role
    execute """
    CREATE TYPE users.chat_participant_role AS ENUM (
        'owner', 'admin', 'moderator', 'member'
    )
    """, "DROP TYPE IF EXISTS users.chat_participant_role"

    # Message type
    execute """
    CREATE TYPE users.message_type AS ENUM (
        'text', 'image', 'gif', 'sticker', 'system'
    )
    """, "DROP TYPE IF EXISTS users.message_type"

    # Activity type
    execute """
    CREATE TYPE users.activity_type AS ENUM (
        'list_add', 'list_update', 'list_complete', 'review_create',
        'review_update', 'favorite_add', 'favorite_remove', 'follow', 'achievement'
    )
    """, "DROP TYPE IF EXISTS users.activity_type"

    # Favorite type
    execute """
    CREATE TYPE users.favorite_type AS ENUM (
        'anime', 'manga', 'character', 'person', 'studio'
    )
    """, "DROP TYPE IF EXISTS users.favorite_type"

    # Theme preference
    execute """
    CREATE TYPE users.theme_preference AS ENUM (
        'light', 'dark', 'system'
    )
    """, "DROP TYPE IF EXISTS users.theme_preference"

    # Title language preference
    execute """
    CREATE TYPE users.title_language AS ENUM (
        'english', 'romaji', 'native'
    )
    """, "DROP TYPE IF EXISTS users.title_language"
  end

  # ============================================================================
  # USERS TABLE
  # ============================================================================
  defp create_users_table do
    execute """
    CREATE TABLE users.users (
        id BIGSERIAL PRIMARY KEY,

        -- Authentication
        identifier CITEXT NOT NULL,
        email CITEXT NOT NULL,
        hashed_password VARCHAR(255),
        confirmed_at TIMESTAMP(0),

        -- Profile information
        name VARCHAR(255) NOT NULL,
        bio TEXT,
        avatar_url VARCHAR(1000),
        banner_url VARCHAR(1000),
        location VARCHAR(100),
        website_url VARCHAR(500),
        birthday DATE,
        gender VARCHAR(20),

        -- Preferences
        timezone VARCHAR(50) DEFAULT 'UTC',
        language VARCHAR(10) DEFAULT 'en',
        theme users.theme_preference DEFAULT 'dark',
        title_language users.title_language DEFAULT 'romaji',

        -- Privacy settings
        is_private BOOLEAN DEFAULT FALSE,
        show_adult_content BOOLEAN DEFAULT FALSE,
        allow_friend_requests BOOLEAN DEFAULT TRUE,
        show_activity BOOLEAN DEFAULT TRUE,
        show_statistics BOOLEAN DEFAULT TRUE,

        -- Aggregated stats (denormalized for performance)
        anime_count INTEGER DEFAULT 0 CHECK (anime_count >= 0),
        manga_count INTEGER DEFAULT 0 CHECK (manga_count >= 0),
        episodes_watched INTEGER DEFAULT 0 CHECK (episodes_watched >= 0),
        chapters_read INTEGER DEFAULT 0 CHECK (chapters_read >= 0),
        days_watched NUMERIC(10,2) DEFAULT 0.0 CHECK (days_watched >= 0),
        days_read NUMERIC(10,2) DEFAULT 0.0 CHECK (days_read >= 0),
        mean_anime_score NUMERIC(4,2) DEFAULT 0.0 CHECK (mean_anime_score >= 0 AND mean_anime_score <= 10),
        mean_manga_score NUMERIC(4,2) DEFAULT 0.0 CHECK (mean_manga_score >= 0 AND mean_manga_score <= 10),
        reviews_count INTEGER DEFAULT 0 CHECK (reviews_count >= 0),
        followers_count INTEGER DEFAULT 0 CHECK (followers_count >= 0),
        following_count INTEGER DEFAULT 0 CHECK (following_count >= 0),

        -- Account status
        status users.user_status DEFAULT 'active',
        role users.user_role DEFAULT 'user',
        is_verified BOOLEAN DEFAULT FALSE,

        -- Moderation
        is_banned BOOLEAN DEFAULT FALSE,
        banned_at TIMESTAMP(0),
        banned_until TIMESTAMP(0),
        ban_reason TEXT,
        warning_count INTEGER DEFAULT 0 CHECK (warning_count >= 0),

        -- Activity tracking
        last_active_at TIMESTAMP(0),
        last_login_at TIMESTAMP(0),
        login_count INTEGER DEFAULT 0 CHECK (login_count >= 0),

        -- Soft delete
        deleted_at TIMESTAMP(0),
        deletion_reason TEXT,

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),

        -- Constraints
        CONSTRAINT users_ban_check CHECK (
            (is_banned = FALSE AND banned_at IS NULL AND ban_reason IS NULL) OR
            (is_banned = TRUE AND banned_at IS NOT NULL)
        )
    )
    """, "DROP TABLE IF EXISTS users.users CASCADE"
  end

  # ============================================================================
  # USER TOKENS TABLE
  # ============================================================================
  defp create_user_tokens_table do
    execute """
    CREATE TABLE users.user_tokens (
        id BIGSERIAL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        token BYTEA NOT NULL,
        context VARCHAR(255) NOT NULL,
        sent_to VARCHAR(255),
        expires_at TIMESTAMP(0),
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS users.user_tokens CASCADE"
  end

  # ============================================================================
  # USER IDENTITIES TABLE
  # ============================================================================
  defp create_user_identities_table do
    execute """
    CREATE TABLE users.user_identities (
        id BIGSERIAL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        provider VARCHAR(50) NOT NULL,
        provider_uid VARCHAR(255) NOT NULL,
        provider_email VARCHAR(255),
        provider_name VARCHAR(255),
        provider_avatar VARCHAR(1000),
        access_token TEXT,
        refresh_token TEXT,
        token_expires_at TIMESTAMP(0),
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS users.user_identities CASCADE"
  end

  # ============================================================================
  # USER SETTINGS TABLE
  # ============================================================================
  defp create_user_settings_table do
    execute """
    CREATE TABLE users.user_settings (
        user_id BIGINT PRIMARY KEY REFERENCES users.users(id) ON DELETE CASCADE,

        -- Notification preferences
        email_notifications BOOLEAN DEFAULT TRUE,
        push_notifications BOOLEAN DEFAULT TRUE,
        notify_follows BOOLEAN DEFAULT TRUE,
        notify_list_updates BOOLEAN DEFAULT TRUE,
        notify_reviews BOOLEAN DEFAULT TRUE,
        notify_mentions BOOLEAN DEFAULT TRUE,
        notify_recommendations BOOLEAN DEFAULT TRUE,
        notify_new_episodes BOOLEAN DEFAULT TRUE,
        notify_new_chapters BOOLEAN DEFAULT TRUE,

        -- Display preferences
        default_list_view VARCHAR(20) DEFAULT 'grid',
        items_per_page INTEGER DEFAULT 25 CHECK (items_per_page >= 10 AND items_per_page <= 100),
        show_spoilers BOOLEAN DEFAULT FALSE,
        autoplay_trailers BOOLEAN DEFAULT TRUE,

        -- List preferences
        default_anime_sort VARCHAR(30) DEFAULT 'last_updated',
        default_manga_sort VARCHAR(30) DEFAULT 'last_updated',

        -- Import/Export
        mal_username VARCHAR(100),
        anilist_username VARCHAR(100),
        last_mal_sync TIMESTAMP(0),
        last_anilist_sync TIMESTAMP(0),

        -- System fields
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS users.user_settings CASCADE"
  end

  # ============================================================================
  # USER ANIME LISTS TABLE
  # ============================================================================
  defp create_user_anime_lists_table do
    execute """
    CREATE TABLE users.user_anime_lists (
        id BIGSERIAL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,

        -- List status
        status users.anime_list_status NOT NULL,

        -- Progress tracking
        score INTEGER CHECK (score IS NULL OR (score >= 1 AND score <= 10)),
        progress INTEGER DEFAULT 0 CHECK (progress >= 0),

        -- Dates
        start_date DATE,
        finish_date DATE,

        -- Additional info
        notes TEXT,
        tags TEXT[] DEFAULT ARRAY[]::TEXT[],

        -- Rewatch tracking
        is_rewatching BOOLEAN DEFAULT FALSE,
        rewatch_count INTEGER DEFAULT 0 CHECK (rewatch_count >= 0),
        rewatch_value INTEGER CHECK (rewatch_value IS NULL OR (rewatch_value >= 1 AND rewatch_value <= 5)),

        -- Flags
        is_favorite BOOLEAN DEFAULT FALSE,
        is_private BOOLEAN DEFAULT FALSE,

        -- Priority (for plan to watch)
        priority INTEGER CHECK (priority IS NULL OR (priority >= 1 AND priority <= 5)),

        -- Custom lists (user-defined categories)
        custom_lists JSONB DEFAULT '[]'::JSONB,

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),

        -- Constraints
        CONSTRAINT user_anime_lists_dates_check CHECK (
            finish_date IS NULL OR start_date IS NULL OR finish_date >= start_date
        )
    )
    """, "DROP TABLE IF EXISTS users.user_anime_lists CASCADE"
  end

  # ============================================================================
  # USER MANGA LISTS TABLE
  # ============================================================================
  defp create_user_manga_lists_table do
    execute """
    CREATE TABLE users.user_manga_lists (
        id BIGSERIAL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,

        -- List status
        status users.manga_list_status NOT NULL,

        -- Progress tracking
        score INTEGER CHECK (score IS NULL OR (score >= 1 AND score <= 10)),
        progress INTEGER DEFAULT 0 CHECK (progress >= 0),
        progress_volumes INTEGER DEFAULT 0 CHECK (progress_volumes >= 0),

        -- Dates
        start_date DATE,
        finish_date DATE,

        -- Additional info
        notes TEXT,
        tags TEXT[] DEFAULT ARRAY[]::TEXT[],

        -- Reread tracking
        is_rereading BOOLEAN DEFAULT FALSE,
        reread_count INTEGER DEFAULT 0 CHECK (reread_count >= 0),
        reread_value INTEGER CHECK (reread_value IS NULL OR (reread_value >= 1 AND reread_value <= 5)),

        -- Flags
        is_favorite BOOLEAN DEFAULT FALSE,
        is_private BOOLEAN DEFAULT FALSE,

        -- Priority
        priority INTEGER CHECK (priority IS NULL OR (priority >= 1 AND priority <= 5)),

        -- Custom lists
        custom_lists JSONB DEFAULT '[]'::JSONB,

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),

        -- Constraints
        CONSTRAINT user_manga_lists_dates_check CHECK (
            finish_date IS NULL OR start_date IS NULL OR finish_date >= start_date
        )
    )
    """, "DROP TABLE IF EXISTS users.user_manga_lists CASCADE"
  end

  # ============================================================================
  # USER EPISODE PROGRESS TABLE
  # ============================================================================
  defp create_user_episode_progress_table do
    execute """
    CREATE TABLE users.user_episode_progress (
        id BIGSERIAL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        episode_id BIGINT NOT NULL REFERENCES contents.episodes(id) ON DELETE CASCADE,
        anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,

        -- Progress
        watched BOOLEAN DEFAULT FALSE,
        watched_at TIMESTAMP(0),
        progress_seconds INTEGER DEFAULT 0 CHECK (progress_seconds >= 0),
        total_seconds INTEGER DEFAULT 0 CHECK (total_seconds >= 0),

        -- Rating
        score INTEGER CHECK (score IS NULL OR (score >= 1 AND score <= 10)),

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS users.user_episode_progress CASCADE"
  end

  # ============================================================================
  # USER CHAPTER PROGRESS TABLE
  # ============================================================================
  defp create_user_chapter_progress_table do
    execute """
    CREATE TABLE users.user_chapter_progress (
        id BIGSERIAL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        chapter_id BIGINT NOT NULL REFERENCES contents.chapters(id) ON DELETE CASCADE,
        manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,

        -- Progress
        read BOOLEAN DEFAULT FALSE,
        read_at TIMESTAMP(0),

        -- Rating
        score INTEGER CHECK (score IS NULL OR (score >= 1 AND score <= 10)),

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS users.user_chapter_progress CASCADE"
  end

  # ============================================================================
  # USER CUSTOM LISTS TABLE
  # ============================================================================
  defp create_user_custom_lists_table do
    execute """
    CREATE TABLE users.user_custom_lists (
        id BIGSERIAL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        name VARCHAR(100) NOT NULL,
        description TEXT,
        is_public BOOLEAN DEFAULT TRUE,
        display_order INTEGER DEFAULT 0,
        color VARCHAR(7),
        icon VARCHAR(50),

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS users.user_custom_lists CASCADE"
  end

  # ============================================================================
  # FAVORITES TABLES
  # ============================================================================
  defp create_favorites_tables do
    # Anime favorites
    execute """
    CREATE TABLE users.user_anime_favorites (
        id BIGSERIAL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
        display_order INTEGER DEFAULT 0,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        UNIQUE (user_id, anime_id)
    )
    """, "DROP TABLE IF EXISTS users.user_anime_favorites CASCADE"

    # Manga favorites
    execute """
    CREATE TABLE users.user_manga_favorites (
        id BIGSERIAL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
        display_order INTEGER DEFAULT 0,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        UNIQUE (user_id, manga_id)
    )
    """, "DROP TABLE IF EXISTS users.user_manga_favorites CASCADE"

    # Character favorites
    execute """
    CREATE TABLE users.user_character_favorites (
        id BIGSERIAL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        character_id BIGINT NOT NULL REFERENCES contents.characters(id) ON DELETE CASCADE,
        display_order INTEGER DEFAULT 0,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        UNIQUE (user_id, character_id)
    )
    """, "DROP TABLE IF EXISTS users.user_character_favorites CASCADE"

    # Person favorites
    execute """
    CREATE TABLE users.user_person_favorites (
        id BIGSERIAL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        person_id BIGINT NOT NULL REFERENCES contents.people(id) ON DELETE CASCADE,
        display_order INTEGER DEFAULT 0,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        UNIQUE (user_id, person_id)
    )
    """, "DROP TABLE IF EXISTS users.user_person_favorites CASCADE"

    # Studio favorites
    execute """
    CREATE TABLE users.user_studio_favorites (
        id BIGSERIAL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        studio_id BIGINT NOT NULL REFERENCES contents.studios(id) ON DELETE CASCADE,
        display_order INTEGER DEFAULT 0,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        UNIQUE (user_id, studio_id)
    )
    """, "DROP TABLE IF EXISTS users.user_studio_favorites CASCADE"
  end

  # ============================================================================
  # USER FOLLOWS TABLE
  # ============================================================================
  defp create_user_follows_table do
    execute """
    CREATE TABLE users.user_follows (
        id BIGSERIAL PRIMARY KEY,
        follower_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        following_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        status users.follow_status DEFAULT 'accepted',
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),

        -- Constraints
        CONSTRAINT user_follows_no_self CHECK (follower_id != following_id),
        UNIQUE (follower_id, following_id)
    )
    """, "DROP TABLE IF EXISTS users.user_follows CASCADE"
  end

  # ============================================================================
  # USER BLOCKS TABLE
  # ============================================================================
  defp create_user_blocks_table do
    execute """
    CREATE TABLE users.user_blocks (
        id BIGSERIAL PRIMARY KEY,
        blocker_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        blocked_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        reason TEXT,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),

        -- Constraints
        CONSTRAINT user_blocks_no_self CHECK (blocker_id != blocked_id),
        UNIQUE (blocker_id, blocked_id)
    )
    """, "DROP TABLE IF EXISTS users.user_blocks CASCADE"
  end

  # ============================================================================
  # REVIEW TABLES
  # ============================================================================
  defp create_review_tables do
    # Anime reviews
    execute """
    CREATE TABLE users.anime_reviews (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,

        -- Content
        title VARCHAR(200),
        content TEXT NOT NULL,

        -- Ratings
        overall_rating INTEGER NOT NULL CHECK (overall_rating >= 1 AND overall_rating <= 10),
        story_rating INTEGER CHECK (story_rating IS NULL OR (story_rating >= 1 AND story_rating <= 10)),
        animation_rating INTEGER CHECK (animation_rating IS NULL OR (animation_rating >= 1 AND animation_rating <= 10)),
        sound_rating INTEGER CHECK (sound_rating IS NULL OR (sound_rating >= 1 AND sound_rating <= 10)),
        character_rating INTEGER CHECK (character_rating IS NULL OR (character_rating >= 1 AND character_rating <= 10)),
        enjoyment_rating INTEGER CHECK (enjoyment_rating IS NULL OR (enjoyment_rating >= 1 AND enjoyment_rating <= 10)),

        -- Status
        status users.review_status DEFAULT 'published',

        -- Flags
        is_spoiler BOOLEAN DEFAULT FALSE,
        contains_adult_content BOOLEAN DEFAULT FALSE,

        -- Engagement stats
        helpful_count INTEGER DEFAULT 0 CHECK (helpful_count >= 0),
        not_helpful_count INTEGER DEFAULT 0 CHECK (not_helpful_count >= 0),
        comment_count INTEGER DEFAULT 0 CHECK (comment_count >= 0),

        -- Moderation
        is_flagged BOOLEAN DEFAULT FALSE,
        flagged_reason TEXT,
        flagged_at TIMESTAMP(0),

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),

        UNIQUE (user_id, anime_id)
    )
    """, "DROP TABLE IF EXISTS users.anime_reviews CASCADE"

    # Manga reviews
    execute """
    CREATE TABLE users.manga_reviews (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,

        -- Content
        title VARCHAR(200),
        content TEXT NOT NULL,

        -- Ratings
        overall_rating INTEGER NOT NULL CHECK (overall_rating >= 1 AND overall_rating <= 10),
        story_rating INTEGER CHECK (story_rating IS NULL OR (story_rating >= 1 AND story_rating <= 10)),
        art_rating INTEGER CHECK (art_rating IS NULL OR (art_rating >= 1 AND art_rating <= 10)),
        character_rating INTEGER CHECK (character_rating IS NULL OR (character_rating >= 1 AND character_rating <= 10)),
        enjoyment_rating INTEGER CHECK (enjoyment_rating IS NULL OR (enjoyment_rating >= 1 AND enjoyment_rating <= 10)),

        -- Status
        status users.review_status DEFAULT 'published',

        -- Flags
        is_spoiler BOOLEAN DEFAULT FALSE,
        contains_adult_content BOOLEAN DEFAULT FALSE,

        -- Engagement stats
        helpful_count INTEGER DEFAULT 0 CHECK (helpful_count >= 0),
        not_helpful_count INTEGER DEFAULT 0 CHECK (not_helpful_count >= 0),
        comment_count INTEGER DEFAULT 0 CHECK (comment_count >= 0),

        -- Moderation
        is_flagged BOOLEAN DEFAULT FALSE,
        flagged_reason TEXT,
        flagged_at TIMESTAMP(0),

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),

        UNIQUE (user_id, manga_id)
    )
    """, "DROP TABLE IF EXISTS users.manga_reviews CASCADE"

    # Anime review votes
    execute """
    CREATE TABLE users.anime_review_votes (
        review_id UUID NOT NULL REFERENCES users.anime_reviews(id) ON DELETE CASCADE,
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        is_helpful BOOLEAN NOT NULL,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (review_id, user_id)
    )
    """, "DROP TABLE IF EXISTS users.anime_review_votes CASCADE"

    # Manga review votes
    execute """
    CREATE TABLE users.manga_review_votes (
        review_id UUID NOT NULL REFERENCES users.manga_reviews(id) ON DELETE CASCADE,
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        is_helpful BOOLEAN NOT NULL,
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        PRIMARY KEY (review_id, user_id)
    )
    """, "DROP TABLE IF EXISTS users.manga_review_votes CASCADE"
  end

  # ============================================================================
  # CHAT TABLES
  # ============================================================================
  defp create_chat_tables do
    # Chat rooms
    execute """
    CREATE TABLE users.chat_rooms (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

        -- Room info
        type users.chat_room_type NOT NULL DEFAULT 'general',
        title VARCHAR(500) NOT NULL,
        description TEXT,

        -- Content association
        anime_id BIGINT REFERENCES contents.anime(id) ON DELETE CASCADE,
        manga_id BIGINT REFERENCES contents.manga(id) ON DELETE CASCADE,
        episode_id BIGINT REFERENCES contents.episodes(id) ON DELETE CASCADE,
        chapter_id BIGINT REFERENCES contents.chapters(id) ON DELETE CASCADE,

        -- Settings
        is_active BOOLEAN DEFAULT TRUE,
        is_public BOOLEAN DEFAULT TRUE,
        is_archived BOOLEAN DEFAULT FALSE,
        requires_registration BOOLEAN DEFAULT FALSE,
        is_moderated BOOLEAN DEFAULT TRUE,
        slow_mode_seconds INTEGER DEFAULT 0 CHECK (slow_mode_seconds >= 0),
        max_participants INTEGER DEFAULT 1000 CHECK (max_participants > 0),

        -- Stats
        message_count INTEGER DEFAULT 0 CHECK (message_count >= 0),
        participant_count INTEGER DEFAULT 0 CHECK (participant_count >= 0),
        active_participants INTEGER DEFAULT 0 CHECK (active_participants >= 0),

        -- Activity
        last_message_at TIMESTAMP(0),

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),

        -- Constraints
        CONSTRAINT chat_rooms_content_check CHECK (
            (type = 'anime' AND anime_id IS NOT NULL) OR
            (type = 'manga' AND manga_id IS NOT NULL) OR
            (type = 'episode' AND episode_id IS NOT NULL AND anime_id IS NOT NULL) OR
            (type = 'chapter' AND chapter_id IS NOT NULL AND manga_id IS NOT NULL) OR
            (type IN ('general', 'private') AND anime_id IS NULL AND manga_id IS NULL AND episode_id IS NULL AND chapter_id IS NULL)
        )
    )
    """, "DROP TABLE IF EXISTS users.chat_rooms CASCADE"

    # Chat messages
    execute """
    CREATE TABLE users.chat_messages (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        chat_room_id UUID NOT NULL REFERENCES users.chat_rooms(id) ON DELETE CASCADE,
        user_id BIGINT REFERENCES users.users(id) ON DELETE SET NULL,

        -- Content
        content TEXT NOT NULL,
        message_type users.message_type DEFAULT 'text',

        -- Reply threading
        reply_to_id UUID REFERENCES users.chat_messages(id) ON DELETE SET NULL,

        -- Reactions
        reactions JSONB DEFAULT '{}'::JSONB,

        -- Edit tracking
        is_edited BOOLEAN DEFAULT FALSE,
        edit_count INTEGER DEFAULT 0 CHECK (edit_count >= 0),
        last_edited_at TIMESTAMP(0),

        -- Moderation
        is_deleted BOOLEAN DEFAULT FALSE,
        deleted_at TIMESTAMP(0),
        deleted_by BIGINT REFERENCES users.users(id) ON DELETE SET NULL,
        deleted_reason TEXT,
        is_flagged BOOLEAN DEFAULT FALSE,
        flagged_reason TEXT,

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS users.chat_messages CASCADE"

    # Chat participants
    execute """
    CREATE TABLE users.chat_participants (
        chat_room_id UUID NOT NULL REFERENCES users.chat_rooms(id) ON DELETE CASCADE,
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,

        -- Role
        role users.chat_participant_role DEFAULT 'member',

        -- Activity
        joined_at TIMESTAMP(0) DEFAULT NOW(),
        last_seen_at TIMESTAMP(0) DEFAULT NOW(),
        last_read_at TIMESTAMP(0),

        -- Status
        is_muted BOOLEAN DEFAULT FALSE,
        muted_until TIMESTAMP(0),
        is_banned BOOLEAN DEFAULT FALSE,
        banned_until TIMESTAMP(0),
        ban_reason TEXT,

        -- Preferences
        notifications_enabled BOOLEAN DEFAULT TRUE,

        PRIMARY KEY (chat_room_id, user_id)
    )
    """, "DROP TABLE IF EXISTS users.chat_participants CASCADE"
  end

  # ============================================================================
  # NOTIFICATIONS TABLE
  # ============================================================================
  defp create_notifications_table do
    execute """
    CREATE TABLE users.notifications (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,

        -- Notification info
        type users.notification_type NOT NULL,
        title VARCHAR(255) NOT NULL,
        message TEXT,

        -- Related content
        data JSONB DEFAULT '{}'::JSONB,

        -- Action URL
        url VARCHAR(1000),

        -- Status
        is_read BOOLEAN DEFAULT FALSE,
        read_at TIMESTAMP(0),

        -- Source user
        source_user_id BIGINT REFERENCES users.users(id) ON DELETE SET NULL,

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS users.notifications CASCADE"
  end

  # ============================================================================
  # USER ACTIVITIES TABLE
  # ============================================================================
  defp create_user_activities_table do
    execute """
    CREATE TABLE users.user_activities (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,

        -- Activity info
        type users.activity_type NOT NULL,

        -- Related content
        anime_id BIGINT REFERENCES contents.anime(id) ON DELETE CASCADE,
        manga_id BIGINT REFERENCES contents.manga(id) ON DELETE CASCADE,

        -- Activity details
        data JSONB DEFAULT '{}'::JSONB,

        -- Privacy
        is_private BOOLEAN DEFAULT FALSE,

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS users.user_activities CASCADE"
  end

  # ============================================================================
  # MODERATION TABLES
  # ============================================================================
  defp create_moderation_tables do
    # Reports
    execute """
    CREATE TABLE users.reports (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        reporter_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,

        -- What's being reported
        reported_type VARCHAR(50) NOT NULL,
        reported_id VARCHAR(255) NOT NULL,

        -- Report details
        type users.report_type NOT NULL,
        description TEXT,
        evidence_urls TEXT[],

        -- Status
        status users.report_status DEFAULT 'pending',

        -- Resolution
        resolved_by BIGINT REFERENCES users.users(id) ON DELETE SET NULL,
        resolved_at TIMESTAMP(0),
        resolution_notes TEXT,
        action_taken VARCHAR(100),

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS users.reports CASCADE"

    # Moderation logs
    execute """
    CREATE TABLE users.moderation_logs (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        moderator_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,

        -- Action target
        target_type VARCHAR(50) NOT NULL,
        target_id VARCHAR(255) NOT NULL,

        -- Action details
        action VARCHAR(100) NOT NULL,
        reason TEXT,

        -- Related report
        report_id UUID REFERENCES users.reports(id) ON DELETE SET NULL,

        -- Metadata
        metadata JSONB DEFAULT '{}'::JSONB,

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS users.moderation_logs CASCADE"

    # User warnings
    execute """
    CREATE TABLE users.user_warnings (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
        moderator_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,

        -- Warning details
        reason TEXT NOT NULL,
        severity INTEGER DEFAULT 1 CHECK (severity >= 1 AND severity <= 5),

        -- Related report
        report_id UUID REFERENCES users.reports(id) ON DELETE SET NULL,

        -- Acknowledgement
        acknowledged BOOLEAN DEFAULT FALSE,
        acknowledged_at TIMESTAMP(0),

        -- Expiry
        expires_at TIMESTAMP(0),

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS users.user_warnings CASCADE"
  end

  # ============================================================================
  # HISTORY TABLES
  # ============================================================================
  defp create_history_tables do
    # User profile change history
    execute """
    CREATE TABLE users.user_history (
        id BIGSERIAL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,

        -- Change tracking
        changed_fields JSONB NOT NULL,
        previous_values JSONB NOT NULL,
        new_values JSONB NOT NULL,

        -- Source
        change_source VARCHAR(50) NOT NULL,
        changed_by BIGINT REFERENCES users.users(id) ON DELETE SET NULL,

        -- System fields
        changed_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS users.user_history CASCADE"

    # Login history
    execute """
    CREATE TABLE users.user_login_history (
        id BIGSERIAL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,

        -- Login details
        ip_address INET,
        user_agent TEXT,
        device_type VARCHAR(50),
        location VARCHAR(100),

        -- Status
        success BOOLEAN NOT NULL,
        failure_reason VARCHAR(100),

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS users.user_login_history CASCADE"
  end

  # ============================================================================
  # IMPORT TABLES
  # ============================================================================
  defp create_import_tables do
    execute """
    CREATE TABLE users.list_import_jobs (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id BIGINT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,

        -- Import source
        source VARCHAR(50) NOT NULL,

        -- Status
        status VARCHAR(50) DEFAULT 'pending',

        -- Progress
        total_items INTEGER DEFAULT 0,
        processed_items INTEGER DEFAULT 0,
        created_items INTEGER DEFAULT 0,
        updated_items INTEGER DEFAULT 0,
        skipped_items INTEGER DEFAULT 0,
        failed_items INTEGER DEFAULT 0,

        -- Errors
        errors JSONB DEFAULT '[]'::JSONB,

        -- Timing
        started_at TIMESTAMP(0),
        completed_at TIMESTAMP(0),

        -- System fields
        inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """, "DROP TABLE IF EXISTS users.list_import_jobs CASCADE"
  end

  # ============================================================================
  # ALL INDEXES
  # ============================================================================
  defp create_all_indexes do
    # User indexes
    execute "CREATE UNIQUE INDEX idx_users_identifier ON users.users (identifier) WHERE deleted_at IS NULL"
    execute "CREATE UNIQUE INDEX idx_users_email ON users.users (email) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_users_status ON users.users (status) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_users_last_active ON users.users (last_active_at DESC) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_users_deleted ON users.users (deleted_at) WHERE deleted_at IS NOT NULL"

    # Token indexes
    execute "CREATE INDEX idx_user_tokens_user ON users.user_tokens (user_id)"
    execute "CREATE UNIQUE INDEX idx_user_tokens_context_token ON users.user_tokens (context, token)"
    execute "CREATE INDEX idx_user_tokens_expires ON users.user_tokens (expires_at) WHERE expires_at IS NOT NULL"

    # Identity indexes
    execute "CREATE INDEX idx_user_identities_user ON users.user_identities (user_id)"
    execute "CREATE UNIQUE INDEX idx_user_identities_provider ON users.user_identities (provider, provider_uid)"

    # Anime list indexes
    execute "CREATE UNIQUE INDEX idx_user_anime_lists_user_anime ON users.user_anime_lists (user_id, anime_id)"
    execute "CREATE INDEX idx_user_anime_lists_user_status ON users.user_anime_lists (user_id, status)"
    execute "CREATE INDEX idx_user_anime_lists_anime ON users.user_anime_lists (anime_id)"
    execute "CREATE INDEX idx_user_anime_lists_updated ON users.user_anime_lists (user_id, updated_at DESC)"
    execute "CREATE INDEX idx_user_anime_lists_score ON users.user_anime_lists (user_id, score DESC) WHERE score IS NOT NULL"
    execute "CREATE INDEX idx_user_anime_lists_favorite ON users.user_anime_lists (user_id) WHERE is_favorite = TRUE"

    # Manga list indexes
    execute "CREATE UNIQUE INDEX idx_user_manga_lists_user_manga ON users.user_manga_lists (user_id, manga_id)"
    execute "CREATE INDEX idx_user_manga_lists_user_status ON users.user_manga_lists (user_id, status)"
    execute "CREATE INDEX idx_user_manga_lists_manga ON users.user_manga_lists (manga_id)"
    execute "CREATE INDEX idx_user_manga_lists_updated ON users.user_manga_lists (user_id, updated_at DESC)"
    execute "CREATE INDEX idx_user_manga_lists_score ON users.user_manga_lists (user_id, score DESC) WHERE score IS NOT NULL"

    # Progress indexes
    execute "CREATE UNIQUE INDEX idx_user_episode_progress_user_episode ON users.user_episode_progress (user_id, episode_id)"
    execute "CREATE INDEX idx_user_episode_progress_anime ON users.user_episode_progress (user_id, anime_id)"
    execute "CREATE UNIQUE INDEX idx_user_chapter_progress_user_chapter ON users.user_chapter_progress (user_id, chapter_id)"
    execute "CREATE INDEX idx_user_chapter_progress_manga ON users.user_chapter_progress (user_id, manga_id)"

    # Favorite indexes
    execute "CREATE INDEX idx_user_anime_favorites_user ON users.user_anime_favorites (user_id, display_order)"
    execute "CREATE INDEX idx_user_manga_favorites_user ON users.user_manga_favorites (user_id, display_order)"
    execute "CREATE INDEX idx_user_character_favorites_user ON users.user_character_favorites (user_id, display_order)"
    execute "CREATE INDEX idx_user_person_favorites_user ON users.user_person_favorites (user_id, display_order)"
    execute "CREATE INDEX idx_user_studio_favorites_user ON users.user_studio_favorites (user_id, display_order)"

    # Follow indexes
    execute "CREATE INDEX idx_user_follows_follower ON users.user_follows (follower_id, status)"
    execute "CREATE INDEX idx_user_follows_following ON users.user_follows (following_id, status)"

    # Block indexes
    execute "CREATE INDEX idx_user_blocks_blocker ON users.user_blocks (blocker_id)"
    execute "CREATE INDEX idx_user_blocks_blocked ON users.user_blocks (blocked_id)"

    # Review indexes
    execute "CREATE INDEX idx_anime_reviews_anime ON users.anime_reviews (anime_id, status)"
    execute "CREATE INDEX idx_anime_reviews_user ON users.anime_reviews (user_id)"
    execute "CREATE INDEX idx_anime_reviews_helpful ON users.anime_reviews (helpful_count DESC) WHERE status = 'published'"
    execute "CREATE INDEX idx_anime_reviews_recent ON users.anime_reviews (inserted_at DESC) WHERE status = 'published'"

    execute "CREATE INDEX idx_manga_reviews_manga ON users.manga_reviews (manga_id, status)"
    execute "CREATE INDEX idx_manga_reviews_user ON users.manga_reviews (user_id)"
    execute "CREATE INDEX idx_manga_reviews_helpful ON users.manga_reviews (helpful_count DESC) WHERE status = 'published'"

    # Chat indexes
    execute "CREATE INDEX idx_chat_rooms_type_content ON users.chat_rooms (type, anime_id, manga_id)"
    execute "CREATE INDEX idx_chat_rooms_active ON users.chat_rooms (is_active, last_message_at DESC)"

    execute "CREATE INDEX idx_chat_messages_room_time ON users.chat_messages (chat_room_id, inserted_at DESC)"
    execute "CREATE INDEX idx_chat_messages_user ON users.chat_messages (user_id, inserted_at DESC)"
    execute "CREATE INDEX idx_chat_messages_reply ON users.chat_messages (reply_to_id) WHERE reply_to_id IS NOT NULL"

    execute "CREATE INDEX idx_chat_participants_user ON users.chat_participants (user_id, last_seen_at DESC)"
    execute "CREATE INDEX idx_chat_participants_room ON users.chat_participants (chat_room_id) WHERE is_banned = FALSE"

    # Notification indexes
    execute "CREATE INDEX idx_notifications_user_unread ON users.notifications (user_id, is_read, inserted_at DESC)"
    execute "CREATE INDEX idx_notifications_user_recent ON users.notifications (user_id, inserted_at DESC)"

    # Activity indexes
    execute "CREATE INDEX idx_user_activities_user ON users.user_activities (user_id, inserted_at DESC) WHERE is_private = FALSE"
    execute "CREATE INDEX idx_user_activities_anime ON users.user_activities (anime_id, inserted_at DESC) WHERE anime_id IS NOT NULL"
    execute "CREATE INDEX idx_user_activities_manga ON users.user_activities (manga_id, inserted_at DESC) WHERE manga_id IS NOT NULL"

    # Report indexes
    execute "CREATE INDEX idx_reports_status ON users.reports (status, inserted_at DESC)"
    execute "CREATE INDEX idx_reports_reporter ON users.reports (reporter_id)"

    # Warning indexes
    execute "CREATE INDEX idx_user_warnings_user ON users.user_warnings (user_id, inserted_at DESC)"
    execute "CREATE INDEX idx_user_warnings_moderator ON users.user_warnings (moderator_id)"
    execute "CREATE INDEX idx_user_warnings_active ON users.user_warnings (user_id) WHERE acknowledged = FALSE"

    # History indexes
    execute "CREATE INDEX idx_user_history_user ON users.user_history (user_id, changed_at DESC)"
    execute "CREATE INDEX idx_user_login_history_user ON users.user_login_history (user_id, inserted_at DESC)"

    # Import job indexes
    execute "CREATE INDEX idx_list_import_jobs_user ON users.list_import_jobs (user_id, inserted_at DESC)"
    execute "CREATE INDEX idx_list_import_jobs_status ON users.list_import_jobs (status)"
  end

  # ============================================================================
  # FUNCTIONS
  # ============================================================================
  defp create_functions do
    # Update user anime stats
    execute """
    CREATE OR REPLACE FUNCTION users.update_user_anime_stats() RETURNS TRIGGER AS $$
    BEGIN
        UPDATE users.users SET
            anime_count = (
                SELECT COUNT(*) FROM users.user_anime_lists
                WHERE user_id = COALESCE(NEW.user_id, OLD.user_id)
            ),
            episodes_watched = (
                SELECT COALESCE(SUM(progress), 0) FROM users.user_anime_lists
                WHERE user_id = COALESCE(NEW.user_id, OLD.user_id)
            ),
            mean_anime_score = (
                SELECT COALESCE(AVG(score), 0) FROM users.user_anime_lists
                WHERE user_id = COALESCE(NEW.user_id, OLD.user_id) AND score IS NOT NULL
            ),
            updated_at = NOW()
        WHERE id = COALESCE(NEW.user_id, OLD.user_id);

        RETURN COALESCE(NEW, OLD);
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS users.update_user_anime_stats()"

    # Update user manga stats
    execute """
    CREATE OR REPLACE FUNCTION users.update_user_manga_stats() RETURNS TRIGGER AS $$
    BEGIN
        UPDATE users.users SET
            manga_count = (
                SELECT COUNT(*) FROM users.user_manga_lists
                WHERE user_id = COALESCE(NEW.user_id, OLD.user_id)
            ),
            chapters_read = (
                SELECT COALESCE(SUM(progress), 0) FROM users.user_manga_lists
                WHERE user_id = COALESCE(NEW.user_id, OLD.user_id)
            ),
            mean_manga_score = (
                SELECT COALESCE(AVG(score), 0) FROM users.user_manga_lists
                WHERE user_id = COALESCE(NEW.user_id, OLD.user_id) AND score IS NOT NULL
            ),
            updated_at = NOW()
        WHERE id = COALESCE(NEW.user_id, OLD.user_id);

        RETURN COALESCE(NEW, OLD);
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS users.update_user_manga_stats()"

    # Update follow counts
    execute """
    CREATE OR REPLACE FUNCTION users.update_follow_counts() RETURNS TRIGGER AS $$
    BEGIN
        IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
            UPDATE users.users SET
                following_count = (
                    SELECT COUNT(*) FROM users.user_follows
                    WHERE follower_id = NEW.follower_id AND status = 'accepted'
                ),
                updated_at = NOW()
            WHERE id = NEW.follower_id;

            UPDATE users.users SET
                followers_count = (
                    SELECT COUNT(*) FROM users.user_follows
                    WHERE following_id = NEW.following_id AND status = 'accepted'
                ),
                updated_at = NOW()
            WHERE id = NEW.following_id;
        END IF;

        IF TG_OP = 'DELETE' THEN
            UPDATE users.users SET
                following_count = (
                    SELECT COUNT(*) FROM users.user_follows
                    WHERE follower_id = OLD.follower_id AND status = 'accepted'
                ),
                updated_at = NOW()
            WHERE id = OLD.follower_id;

            UPDATE users.users SET
                followers_count = (
                    SELECT COUNT(*) FROM users.user_follows
                    WHERE following_id = OLD.following_id AND status = 'accepted'
                ),
                updated_at = NOW()
            WHERE id = OLD.following_id;
        END IF;

        RETURN COALESCE(NEW, OLD);
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS users.update_follow_counts()"

    # Update anime review votes
    execute """
    CREATE OR REPLACE FUNCTION users.update_anime_review_votes() RETURNS TRIGGER AS $$
    BEGIN
        UPDATE users.anime_reviews SET
            helpful_count = (
                SELECT COUNT(*) FROM users.anime_review_votes
                WHERE review_id = COALESCE(NEW.review_id, OLD.review_id) AND is_helpful = TRUE
            ),
            not_helpful_count = (
                SELECT COUNT(*) FROM users.anime_review_votes
                WHERE review_id = COALESCE(NEW.review_id, OLD.review_id) AND is_helpful = FALSE
            ),
            updated_at = NOW()
        WHERE id = COALESCE(NEW.review_id, OLD.review_id);

        RETURN COALESCE(NEW, OLD);
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS users.update_anime_review_votes()"

    # Update manga review votes
    execute """
    CREATE OR REPLACE FUNCTION users.update_manga_review_votes() RETURNS TRIGGER AS $$
    BEGIN
        UPDATE users.manga_reviews SET
            helpful_count = (
                SELECT COUNT(*) FROM users.manga_review_votes
                WHERE review_id = COALESCE(NEW.review_id, OLD.review_id) AND is_helpful = TRUE
            ),
            not_helpful_count = (
                SELECT COUNT(*) FROM users.manga_review_votes
                WHERE review_id = COALESCE(NEW.review_id, OLD.review_id) AND is_helpful = FALSE
            ),
            updated_at = NOW()
        WHERE id = COALESCE(NEW.review_id, OLD.review_id);

        RETURN COALESCE(NEW, OLD);
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS users.update_manga_review_votes()"

    # Update chat room stats
    execute """
    CREATE OR REPLACE FUNCTION users.update_chat_room_stats() RETURNS TRIGGER AS $$
    BEGIN
        IF TG_TABLE_NAME = 'chat_messages' THEN
            UPDATE users.chat_rooms SET
                message_count = (
                    SELECT COUNT(*) FROM users.chat_messages
                    WHERE chat_room_id = COALESCE(NEW.chat_room_id, OLD.chat_room_id)
                    AND is_deleted = FALSE
                ),
                last_message_at = NOW(),
                updated_at = NOW()
            WHERE id = COALESCE(NEW.chat_room_id, OLD.chat_room_id);
        END IF;

        IF TG_TABLE_NAME = 'chat_participants' THEN
            UPDATE users.chat_rooms SET
                participant_count = (
                    SELECT COUNT(*) FROM users.chat_participants
                    WHERE chat_room_id = COALESCE(NEW.chat_room_id, OLD.chat_room_id)
                    AND is_banned = FALSE
                ),
                updated_at = NOW()
            WHERE id = COALESCE(NEW.chat_room_id, OLD.chat_room_id);
        END IF;

        RETURN COALESCE(NEW, OLD);
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS users.update_chat_room_stats()"

    # Generic updated_at trigger
    execute """
    CREATE OR REPLACE FUNCTION users.update_updated_at() RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """, "DROP FUNCTION IF EXISTS users.update_updated_at()"
  end

  # ============================================================================
  # TRIGGERS
  # ============================================================================
  defp create_triggers do
    # User stats triggers
    execute """
    CREATE TRIGGER user_anime_lists_stats_trigger
        AFTER INSERT OR UPDATE OR DELETE ON users.user_anime_lists
        FOR EACH ROW EXECUTE FUNCTION users.update_user_anime_stats()
    """

    execute """
    CREATE TRIGGER user_manga_lists_stats_trigger
        AFTER INSERT OR UPDATE OR DELETE ON users.user_manga_lists
        FOR EACH ROW EXECUTE FUNCTION users.update_user_manga_stats()
    """

    # Follow count triggers
    execute """
    CREATE TRIGGER user_follows_count_trigger
        AFTER INSERT OR UPDATE OR DELETE ON users.user_follows
        FOR EACH ROW EXECUTE FUNCTION users.update_follow_counts()
    """

    # Review vote triggers
    execute """
    CREATE TRIGGER anime_review_votes_trigger
        AFTER INSERT OR UPDATE OR DELETE ON users.anime_review_votes
        FOR EACH ROW EXECUTE FUNCTION users.update_anime_review_votes()
    """

    execute """
    CREATE TRIGGER manga_review_votes_trigger
        AFTER INSERT OR UPDATE OR DELETE ON users.manga_review_votes
        FOR EACH ROW EXECUTE FUNCTION users.update_manga_review_votes()
    """

    # Chat stats triggers
    execute """
    CREATE TRIGGER chat_messages_stats_trigger
        AFTER INSERT OR UPDATE OR DELETE ON users.chat_messages
        FOR EACH ROW EXECUTE FUNCTION users.update_chat_room_stats()
    """

    execute """
    CREATE TRIGGER chat_participants_stats_trigger
        AFTER INSERT OR UPDATE OR DELETE ON users.chat_participants
        FOR EACH ROW EXECUTE FUNCTION users.update_chat_room_stats()
    """

    # Updated at triggers
    execute """
    CREATE TRIGGER users_updated_at_trigger
        BEFORE UPDATE ON users.users
        FOR EACH ROW EXECUTE FUNCTION users.update_updated_at()
    """

    execute """
    CREATE TRIGGER user_identities_updated_at_trigger
        BEFORE UPDATE ON users.user_identities
        FOR EACH ROW EXECUTE FUNCTION users.update_updated_at()
    """

    execute """
    CREATE TRIGGER user_settings_updated_at_trigger
        BEFORE UPDATE ON users.user_settings
        FOR EACH ROW EXECUTE FUNCTION users.update_updated_at()
    """

    execute """
    CREATE TRIGGER user_anime_lists_updated_at_trigger
        BEFORE UPDATE ON users.user_anime_lists
        FOR EACH ROW EXECUTE FUNCTION users.update_updated_at()
    """

    execute """
    CREATE TRIGGER user_manga_lists_updated_at_trigger
        BEFORE UPDATE ON users.user_manga_lists
        FOR EACH ROW EXECUTE FUNCTION users.update_updated_at()
    """

    execute """
    CREATE TRIGGER user_episode_progress_updated_at_trigger
        BEFORE UPDATE ON users.user_episode_progress
        FOR EACH ROW EXECUTE FUNCTION users.update_updated_at()
    """

    execute """
    CREATE TRIGGER user_chapter_progress_updated_at_trigger
        BEFORE UPDATE ON users.user_chapter_progress
        FOR EACH ROW EXECUTE FUNCTION users.update_updated_at()
    """

    execute """
    CREATE TRIGGER user_custom_lists_updated_at_trigger
        BEFORE UPDATE ON users.user_custom_lists
        FOR EACH ROW EXECUTE FUNCTION users.update_updated_at()
    """

    execute """
    CREATE TRIGGER user_follows_updated_at_trigger
        BEFORE UPDATE ON users.user_follows
        FOR EACH ROW EXECUTE FUNCTION users.update_updated_at()
    """

    execute """
    CREATE TRIGGER anime_reviews_updated_at_trigger
        BEFORE UPDATE ON users.anime_reviews
        FOR EACH ROW EXECUTE FUNCTION users.update_updated_at()
    """

    execute """
    CREATE TRIGGER manga_reviews_updated_at_trigger
        BEFORE UPDATE ON users.manga_reviews
        FOR EACH ROW EXECUTE FUNCTION users.update_updated_at()
    """

    execute """
    CREATE TRIGGER chat_rooms_updated_at_trigger
        BEFORE UPDATE ON users.chat_rooms
        FOR EACH ROW EXECUTE FUNCTION users.update_updated_at()
    """

    execute """
    CREATE TRIGGER chat_messages_updated_at_trigger
        BEFORE UPDATE ON users.chat_messages
        FOR EACH ROW EXECUTE FUNCTION users.update_updated_at()
    """

    execute """
    CREATE TRIGGER reports_updated_at_trigger
        BEFORE UPDATE ON users.reports
        FOR EACH ROW EXECUTE FUNCTION users.update_updated_at()
    """

    execute """
    CREATE TRIGGER list_import_jobs_updated_at_trigger
        BEFORE UPDATE ON users.list_import_jobs
        FOR EACH ROW EXECUTE FUNCTION users.update_updated_at()
    """
  end

  # ============================================================================
  # VIEWS
  # ============================================================================
  defp create_views do
    # User public profile view
    execute """
    CREATE VIEW users.user_profiles AS
    SELECT
        id,
        identifier,
        name,
        bio,
        avatar_url,
        banner_url,
        location,
        website_url,
        is_private,
        is_verified,
        role,
        anime_count,
        manga_count,
        episodes_watched,
        chapters_read,
        days_watched,
        mean_anime_score,
        mean_manga_score,
        reviews_count,
        followers_count,
        following_count,
        last_active_at,
        inserted_at
    FROM users.users
    WHERE deleted_at IS NULL AND status = 'active'
    """, "DROP VIEW IF EXISTS users.user_profiles"

    # User anime list with anime details
    execute """
    CREATE VIEW users.user_anime_list_details AS
    SELECT
        ual.id,
        ual.user_id,
        ual.anime_id,
        ual.status,
        ual.score,
        ual.progress,
        ual.start_date,
        ual.finish_date,
        ual.is_favorite,
        ual.is_rewatching,
        ual.rewatch_count,
        ual.updated_at,
        a.title_en,
        a.title_ja,
        a.cover_image_url,
        a.type,
        a.status AS anime_status,
        a.episodes AS total_episodes,
        a.mal_score
    FROM users.user_anime_lists ual
    JOIN contents.anime a ON ual.anime_id = a.id
    WHERE a.deleted_at IS NULL
    """, "DROP VIEW IF EXISTS users.user_anime_list_details"

    # User manga list with manga details
    execute """
    CREATE VIEW users.user_manga_list_details AS
    SELECT
        uml.id,
        uml.user_id,
        uml.manga_id,
        uml.status,
        uml.score,
        uml.progress,
        uml.progress_volumes,
        uml.start_date,
        uml.finish_date,
        uml.is_favorite,
        uml.is_rereading,
        uml.reread_count,
        uml.updated_at,
        m.title_en,
        m.title_ja,
        m.cover_image_url,
        m.type,
        m.status AS manga_status,
        m.chapters AS total_chapters,
        m.volumes AS total_volumes,
        m.mal_score
    FROM users.user_manga_lists uml
    JOIN contents.manga m ON uml.manga_id = m.id
    WHERE m.deleted_at IS NULL
    """, "DROP VIEW IF EXISTS users.user_manga_list_details"
  end

  # ============================================================================
  # COMMENTS
  # ============================================================================
  defp create_comments do
    execute "COMMENT ON TABLE users.users IS 'User accounts with profile information and aggregated stats'"
    execute "COMMENT ON TABLE users.user_anime_lists IS 'User anime tracking lists with progress and ratings'"
    execute "COMMENT ON TABLE users.user_manga_lists IS 'User manga tracking lists with progress and ratings'"
    execute "COMMENT ON TABLE users.user_follows IS 'Social graph for user following relationships'"
    execute "COMMENT ON TABLE users.anime_reviews IS 'User reviews for anime with detailed ratings'"
    execute "COMMENT ON TABLE users.manga_reviews IS 'User reviews for manga with detailed ratings'"
    execute "COMMENT ON TABLE users.chat_rooms IS 'Discussion rooms for anime, manga, and general topics'"
    execute "COMMENT ON TABLE users.chat_messages IS 'Messages in chat rooms with threading support'"
    execute "COMMENT ON TABLE users.notifications IS 'User notifications for various events'"
    execute "COMMENT ON TABLE users.user_activities IS 'Activity feed for user actions'"
    execute "COMMENT ON TABLE users.reports IS 'User-submitted content reports for moderation'"
  end
end