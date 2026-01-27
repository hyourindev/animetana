defmodule Yunaos.Repo.Migrations.CreateAdditionalContentTables do
  use Ecto.Migration

  def change do
    # ========================================================================
    # More Info (from /anime/{id}/moreinfo, /manga/{id}/moreinfo)
    # Additional text like viewing order suggestions
    # ========================================================================

    alter table(:anime) do
      add :more_info, :text
    end

    alter table(:manga) do
      add :more_info, :text
    end

    # ========================================================================
    # Score Distributions (from /anime/{id}/statistics, /manga/{id}/statistics)
    # 10 rows per anime/manga, one per score value (1-10)
    # ========================================================================

    create table(:score_distributions) do
      add :scoreable_type, :string, size: 20, null: false
      add :scoreable_id, :bigint, null: false

      add :score, :integer, null: false
      add :votes, :integer, default: 0
      add :percentage, :decimal, precision: 5, scale: 2, default: 0.0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:score_distributions, [:scoreable_type, :scoreable_id, :score])
    create index(:score_distributions, [:scoreable_type, :scoreable_id])

    # ========================================================================
    # Pictures (from /anime/{id}/pictures, /manga/{id}/pictures,
    #           /characters/{id}/pictures, /people/{id}/pictures)
    # Gallery images with JPG and WebP variants at multiple resolutions
    # ========================================================================

    create table(:pictures) do
      add :imageable_type, :string, size: 20, null: false
      add :imageable_id, :bigint, null: false

      # JPG variants
      add :jpg_image_url, :string, size: 1000
      add :jpg_small_image_url, :string, size: 1000
      add :jpg_large_image_url, :string, size: 1000

      # WebP variants
      add :webp_image_url, :string, size: 1000
      add :webp_small_image_url, :string, size: 1000
      add :webp_large_image_url, :string, size: 1000

      timestamps(type: :utc_datetime)
    end

    create index(:pictures, [:imageable_type, :imageable_id])

    # ========================================================================
    # Magazines (from /magazines)
    # Manga publishers/magazines from MAL
    # ========================================================================

    create table(:magazines) do
      add :mal_id, :integer, null: false
      add :name, :string, size: 200, null: false
      add :url, :string, size: 1000
      add :count, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:magazines, [:mal_id])
    create unique_index(:magazines, [:name])

    # ========================================================================
    # Manga-Magazine relationships
    # ========================================================================

    create table(:manga_magazines, primary_key: false) do
      add :manga_id, references(:manga, on_delete: :delete_all), null: false, primary_key: true
      add :magazine_id, references(:magazines, on_delete: :delete_all), null: false, primary_key: true
    end

    create index(:manga_magazines, [:magazine_id])
  end
end
