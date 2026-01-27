defmodule Yunaos.Repo.Migrations.CreateContentTables do
  use Ecto.Migration

  def change do
    # ── Anime ──
    create table(:anime) do
      # Identifiers
      add :mal_id, :integer
      add :anilist_id, :integer
      add :kitsu_id, :integer

      # Basic Information
      add :title, :string, size: 500, null: false
      add :title_english, :string, size: 500
      add :title_japanese, :string, size: 500
      add :title_romaji, :string, size: 500
      add :title_synonyms, {:array, :text}, default: []

      # Content Details
      add :synopsis, :text
      add :background, :text

      # Media URLs
      add :cover_image_url, :string, size: 1000
      add :banner_image_url, :string, size: 1000
      add :trailer_url, :string, size: 1000

      # Classification
      add :type, :string, size: 50, null: false
      add :source, :string, size: 100
      add :status, :string, size: 50, null: false
      add :rating, :string, size: 20

      # Episode Information
      add :episodes, :integer
      add :duration, :integer

      # Broadcast Information
      add :start_date, :date
      add :end_date, :date
      add :season, :string, size: 20
      add :season_year, :integer
      add :broadcast_day, :string, size: 20
      add :broadcast_time, :time

      # MAL Statistics
      add :mal_score, :decimal, precision: 4, scale: 2
      add :mal_scored_by, :integer
      add :mal_rank, :integer
      add :mal_popularity, :integer
      add :mal_members, :integer
      add :mal_favorites, :integer

      # YunAOS Statistics
      add :average_rating, :decimal, precision: 4, scale: 2, default: 0.0
      add :rating_count, :integer, default: 0
      add :members_count, :integer, default: 0
      add :favorites_count, :integer, default: 0
      add :completed_count, :integer, default: 0
      add :watching_count, :integer, default: 0
      add :plan_to_watch_count, :integer, default: 0

      # Search Optimization
      add :search_vector, :tsvector

      # API Sync
      add :last_synced_at, :utc_datetime
      add :sync_status, :string, size: 50, default: "pending"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:anime, [:mal_id])

    # ── Episodes ──
    create table(:episodes) do
      add :anime_id, references(:anime, on_delete: :delete_all), null: false

      add :episode_number, :decimal, precision: 8, scale: 2, null: false
      add :mal_id, :integer

      add :title, :string, size: 500
      add :title_english, :string, size: 500
      add :title_japanese, :string, size: 500
      add :title_romaji, :string, size: 500

      add :synopsis, :text

      add :thumbnail_url, :string, size: 1000

      add :aired, :date
      add :duration, :integer

      add :average_rating, :decimal, precision: 4, scale: 2, default: 0.0
      add :rating_count, :integer, default: 0

      add :is_filler, :boolean, default: false
      add :is_recap, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:episodes, [:anime_id, :episode_number])

    # ── Manga ──
    create table(:manga) do
      # Identifiers
      add :mal_id, :integer
      add :anilist_id, :integer

      # Basic Information
      add :title, :string, size: 500, null: false
      add :title_english, :string, size: 500
      add :title_japanese, :string, size: 500
      add :title_romaji, :string, size: 500
      add :title_synonyms, {:array, :text}, default: []

      # Content Details
      add :synopsis, :text
      add :background, :text

      # Media URLs
      add :cover_image_url, :string, size: 1000
      add :banner_image_url, :string, size: 1000

      # Classification
      add :type, :string, size: 50, null: false
      add :status, :string, size: 50, null: false

      # Content counts
      add :chapters, :integer
      add :volumes, :integer

      # Publication dates
      add :published_from, :date
      add :published_to, :date

      # MAL Statistics
      add :mal_score, :decimal, precision: 4, scale: 2
      add :mal_scored_by, :integer
      add :mal_rank, :integer
      add :mal_popularity, :integer
      add :mal_members, :integer
      add :mal_favorites, :integer

      # YunAOS Statistics
      add :average_rating, :decimal, precision: 4, scale: 2, default: 0.0
      add :rating_count, :integer, default: 0
      add :members_count, :integer, default: 0
      add :favorites_count, :integer, default: 0
      add :completed_count, :integer, default: 0
      add :reading_count, :integer, default: 0
      add :plan_to_read_count, :integer, default: 0

      # Search Optimization
      add :search_vector, :tsvector

      # API Sync
      add :last_synced_at, :utc_datetime
      add :sync_status, :string, size: 50, default: "pending"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:manga, [:mal_id])

    # ── Chapters ──
    create table(:chapters) do
      add :manga_id, references(:manga, on_delete: :delete_all), null: false

      add :chapter_number, :decimal, precision: 8, scale: 2, null: false
      add :volume_number, :integer

      add :title, :string, size: 500
      add :title_english, :string, size: 500
      add :title_japanese, :string, size: 500
      add :title_romaji, :string, size: 500

      add :synopsis, :text
      add :page_count, :integer

      add :published, :date

      add :average_rating, :decimal, precision: 4, scale: 2, default: 0.0
      add :rating_count, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:chapters, [:manga_id, :chapter_number])
  end
end
