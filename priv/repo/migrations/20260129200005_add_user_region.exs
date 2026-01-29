defmodule Animetana.Repo.Migrations.AddUserRegion do
  @moduledoc """
  Adds region field to users to separate JP and Global (EN) communities.

  This is critical because:
  - Stats are separate (Animetana_score_en vs Animetana_score_ja)
  - Users can't interact across regions
  - Threads, reviews, activities are region-specific
  """

  use Ecto.Migration

  def change do
    # Create enum for user region
    execute """
    CREATE TYPE users.user_region AS ENUM ('global', 'jp')
    """, "DROP TYPE IF EXISTS users.user_region"

    # Add region column to users table
    execute """
    ALTER TABLE users.users ADD COLUMN region users.user_region NOT NULL DEFAULT 'global'
    """, """
    ALTER TABLE users.users DROP COLUMN region
    """

    # Create index for region-based queries (very common filter)
    execute "CREATE INDEX idx_users_region ON users.users (region)"

    # Composite indexes for region-scoped queries
    execute "CREATE INDEX idx_users_region_status ON users.users (region, status) WHERE deleted_at IS NULL"
    execute "CREATE INDEX idx_users_region_active ON users.users (region, last_active_at DESC) WHERE deleted_at IS NULL"
  end
end
