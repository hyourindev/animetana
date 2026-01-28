defmodule Yunaos.Repo.Migrations.CreateSubGenresAndEnrichmentColumns do
  use Ecto.Migration

  def change do
    # ── New tables ──

    create table(:sub_genres) do
      add :name, :string, size: 100, null: false
      add :name_ja, :string, size: 100
      add :description, :text
      add :description_ja, :text

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:sub_genres, [:name])

    create table(:genre_sub_genres, primary_key: false) do
      add :genre_id, references(:genres, on_delete: :delete_all), null: false
      add :sub_genre_id, references(:sub_genres, on_delete: :delete_all), null: false
    end

    create unique_index(:genre_sub_genres, [:genre_id, :sub_genre_id])

    create table(:anime_sub_genres, primary_key: false) do
      add :anime_id, references(:anime, on_delete: :delete_all), null: false
      add :sub_genre_id, references(:sub_genres, on_delete: :delete_all), null: false
    end

    create unique_index(:anime_sub_genres, [:anime_id, :sub_genre_id])

    create table(:manga_sub_genres, primary_key: false) do
      add :manga_id, references(:manga, on_delete: :delete_all), null: false
      add :sub_genre_id, references(:sub_genres, on_delete: :delete_all), null: false
    end

    create unique_index(:manga_sub_genres, [:manga_id, :sub_genre_id])

    # ── Alter anime — all nullable, no defaults that break existing rows ──

    alter table(:anime) do
      add :synopsis_ja, :text
      add :mood_tags, :jsonb
      add :content_warnings, :jsonb
      add :similar_to, :jsonb
      add :pacing, :string, size: 20
      add :art_style, :text
      add :art_style_ja, :text
      add :target_audience, :string, size: 20
      add :fun_facts, :jsonb
      add :enriched, :boolean, default: false
    end

    # ── Alter manga — all nullable ──

    alter table(:manga) do
      add :synopsis_ja, :text
      add :mood_tags, :jsonb
      add :content_warnings, :jsonb
      add :similar_to, :jsonb
      add :pacing, :string, size: 20
      add :art_style, :text
      add :art_style_ja, :text
      add :target_audience, :string, size: 20
      add :fun_facts, :jsonb
      add :enriched, :boolean, default: false
    end

    # ── Alter characters — all nullable ──

    alter table(:characters) do
      add :role_description, :text
      add :role_description_ja, :text
      add :personality_tags, :jsonb
      add :gender, :string, size: 20
      add :age, :string, size: 50
      add :height, :string, size: 20
      add :weight, :string, size: 20
      add :blood_type, :string, size: 10
      add :measurements, :string, size: 50
      add :enriched, :boolean, default: false
    end

    # ── Alter people — all nullable ──

    alter table(:people) do
      add :gender, :string, size: 20
      add :blood_type, :string, size: 10
      add :height, :string, size: 20
      add :weight, :string, size: 20
      add :measurements, :string, size: 50
      add :hometown, :string, size: 200
      add :hometown_ja, :string, size: 200
      add :social_twitter, :string, size: 500
      add :social_instagram, :string, size: 500
      add :social_youtube, :string, size: 500
      add :social_tiktok, :string, size: 500
      add :social_website, :string, size: 500
      add :notable_works, :jsonb
      add :enriched, :boolean, default: false
    end

    # ── Alter genres / themes / demographics — add Japanese + fill descriptions ──

    alter table(:genres) do
      add :name_ja, :string, size: 100
      add :description_ja, :text
    end

    alter table(:themes) do
      add :name_ja, :string, size: 100
      add :description_ja, :text
    end

    alter table(:demographics) do
      add :name_ja, :string, size: 100
      add :description_ja, :text
    end
  end
end
