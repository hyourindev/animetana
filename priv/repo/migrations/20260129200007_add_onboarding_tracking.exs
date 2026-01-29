defmodule Animetana.Repo.Migrations.AddOnboardingTracking do
  @moduledoc """
  Adds onboarding_completed_at to track if user has completed initial setup (region selection).
  Users without this set will be redirected to complete onboarding.
  """

  use Ecto.Migration

  def change do
    execute """
    ALTER TABLE users.users ADD COLUMN onboarding_completed_at TIMESTAMP(0) DEFAULT NULL
    """, """
    ALTER TABLE users.users DROP COLUMN onboarding_completed_at
    """

    # Index for finding users who haven't completed onboarding
    execute "CREATE INDEX idx_users_onboarding_pending ON users.users (id) WHERE onboarding_completed_at IS NULL AND deleted_at IS NULL"
  end
end
