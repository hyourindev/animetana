defmodule Yunaos.Repo.Migrations.ExtendUsersForPlatform do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # Profile
      add :bio, :text
      add :avatar_url, :string, size: 1000
      add :banner_url, :string, size: 1000
      add :location, :string, size: 100
      add :website_url, :string, size: 500
      add :birthday, :date
      add :gender, :string, size: 20

      # Platform Preferences
      add :timezone, :string, size: 50, default: "UTC"
      add :language, :string, size: 10, default: "en"
      add :theme, :string, size: 20, default: "dark"

      # Privacy Settings
      add :is_private, :boolean, default: false
      add :show_adult_content, :boolean, default: false
      add :allow_friend_requests, :boolean, default: true

      # Anime/Manga Statistics
      add :anime_count, :integer, default: 0
      add :manga_count, :integer, default: 0
      add :episodes_watched, :integer, default: 0
      add :chapters_read, :integer, default: 0
      add :days_watched, :decimal, precision: 10, scale: 2, default: 0.0
      add :mean_anime_score, :decimal, precision: 3, scale: 1, default: 0.0
      add :mean_manga_score, :decimal, precision: 3, scale: 1, default: 0.0

      # Account Status
      add :is_banned, :boolean, default: false
      add :banned_until, :utc_datetime
      add :ban_reason, :text
      add :last_active_at, :utc_datetime
    end

    create index(:users, [:last_active_at])
  end
end
