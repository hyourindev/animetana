defmodule Yunaos.Repo.Migrations.CreateReviewsAndSocial do
  use Ecto.Migration

  def change do
    # ── Reviews ──
    create table(:reviews, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :user_id, references(:users, on_delete: :delete_all), null: false

      add :reviewable_type, :string, size: 20, null: false
      add :reviewable_id, :bigint, null: false

      add :title, :string, size: 200
      add :content, :text, null: false
      add :rating, :integer, null: false

      add :story_rating, :integer
      add :art_rating, :integer
      add :sound_rating, :integer
      add :character_rating, :integer
      add :enjoyment_rating, :integer

      add :is_published, :boolean, default: false
      add :is_spoiler, :boolean, default: false
      add :contains_adult_content, :boolean, default: false

      add :helpful_votes, :integer, default: 0
      add :total_votes, :integer, default: 0

      add :is_flagged, :boolean, default: false
      add :flagged_reason, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:reviews, [:user_id, :reviewable_type, :reviewable_id])

    # ── Review Votes ──
    create table(:review_votes, primary_key: false) do
      add :review_id, references(:reviews, type: :uuid, on_delete: :delete_all), null: false, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), null: false, primary_key: true

      add :is_helpful, :boolean, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:review_votes, [:review_id])

    # ── User Follows ──
    create table(:user_follows, primary_key: false) do
      add :follower_id, references(:users, on_delete: :delete_all), null: false, primary_key: true
      add :following_id, references(:users, on_delete: :delete_all), null: false, primary_key: true

      add :status, :string, size: 20, default: "pending"

      timestamps(type: :utc_datetime)
    end

    create index(:user_follows, [:following_id])

    create constraint(:user_follows, :cannot_follow_self, check: "follower_id != following_id")
  end
end
