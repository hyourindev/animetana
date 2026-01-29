defmodule Animetana.Repo.Migrations.AddRegionToContentTables do
  @moduledoc """
  Adds region column to user-generated content tables for fast region-scoped queries.

  Region is denormalized to avoid joins on every query. Since region is essentially
  immutable (users don't switch between JP and Global), consistency is not a concern.

  Tables updated:
  - threads: Discussion threads are region-specific
  - anime_reviews: Reviews are separate per region
  - manga_reviews: Reviews are separate per region
  - user_activities: Activity feeds are region-scoped
  """

  use Ecto.Migration

  def change do
    # ============================================================================
    # ADD REGION TO THREADS
    # ============================================================================
    execute """
    ALTER TABLE users.threads ADD COLUMN region users.user_region NOT NULL DEFAULT 'global'
    """, """
    ALTER TABLE users.threads DROP COLUMN region
    """

    execute "CREATE INDEX idx_threads_region ON users.threads (region)"
    execute "CREATE INDEX idx_threads_region_type ON users.threads (region, type) WHERE is_active = TRUE"
    execute "CREATE INDEX idx_threads_region_anime ON users.threads (region, anime_id) WHERE anime_id IS NOT NULL"
    execute "CREATE INDEX idx_threads_region_manga ON users.threads (region, manga_id) WHERE manga_id IS NOT NULL"
    execute "CREATE INDEX idx_threads_region_recent ON users.threads (region, last_message_at DESC) WHERE is_active = TRUE"

    # ============================================================================
    # ADD REGION TO ANIME REVIEWS
    # ============================================================================
    execute """
    ALTER TABLE users.anime_reviews ADD COLUMN region users.user_region NOT NULL DEFAULT 'global'
    """, """
    ALTER TABLE users.anime_reviews DROP COLUMN region
    """

    execute "CREATE INDEX idx_anime_reviews_region ON users.anime_reviews (region)"
    execute "CREATE INDEX idx_anime_reviews_region_anime ON users.anime_reviews (region, anime_id) WHERE status = 'published'"
    execute "CREATE INDEX idx_anime_reviews_region_helpful ON users.anime_reviews (region, helpful_count DESC) WHERE status = 'published'"
    execute "CREATE INDEX idx_anime_reviews_region_recent ON users.anime_reviews (region, inserted_at DESC) WHERE status = 'published'"

    # ============================================================================
    # ADD REGION TO MANGA REVIEWS
    # ============================================================================
    execute """
    ALTER TABLE users.manga_reviews ADD COLUMN region users.user_region NOT NULL DEFAULT 'global'
    """, """
    ALTER TABLE users.manga_reviews DROP COLUMN region
    """

    execute "CREATE INDEX idx_manga_reviews_region ON users.manga_reviews (region)"
    execute "CREATE INDEX idx_manga_reviews_region_manga ON users.manga_reviews (region, manga_id) WHERE status = 'published'"
    execute "CREATE INDEX idx_manga_reviews_region_helpful ON users.manga_reviews (region, helpful_count DESC) WHERE status = 'published'"
    execute "CREATE INDEX idx_manga_reviews_region_recent ON users.manga_reviews (region, inserted_at DESC) WHERE status = 'published'"

    # ============================================================================
    # ADD REGION TO USER ACTIVITIES
    # ============================================================================
    execute """
    ALTER TABLE users.user_activities ADD COLUMN region users.user_region NOT NULL DEFAULT 'global'
    """, """
    ALTER TABLE users.user_activities DROP COLUMN region
    """

    execute "CREATE INDEX idx_user_activities_region ON users.user_activities (region)"
    execute "CREATE INDEX idx_user_activities_region_recent ON users.user_activities (region, inserted_at DESC) WHERE is_private = FALSE"
    execute "CREATE INDEX idx_user_activities_region_anime ON users.user_activities (region, anime_id, inserted_at DESC) WHERE anime_id IS NOT NULL AND is_private = FALSE"
    execute "CREATE INDEX idx_user_activities_region_manga ON users.user_activities (region, manga_id, inserted_at DESC) WHERE manga_id IS NOT NULL AND is_private = FALSE"

    # ============================================================================
    # UPDATE VIEWS TO INCLUDE REGION
    # ============================================================================

    # Drop and recreate user_profiles view to include region
    execute "DROP VIEW IF EXISTS users.user_profiles"

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
        region,
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
    """, """
    DROP VIEW IF EXISTS users.user_profiles;
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
    """
  end
end
