defmodule Yunaos.Repo.Migrations.CreateContentRelationships do
  use Ecto.Migration

  def change do
    # ── Anime-Genre ──
    create table(:anime_genres, primary_key: false) do
      add :anime_id, references(:anime, on_delete: :delete_all), null: false, primary_key: true
      add :genre_id, references(:genres, on_delete: :delete_all), null: false, primary_key: true
    end

    create index(:anime_genres, [:genre_id])

    # ── Anime-Demographics ──
    create table(:anime_demographics, primary_key: false) do
      add :anime_id, references(:anime, on_delete: :delete_all), null: false, primary_key: true
      add :demographic_id, references(:demographics, on_delete: :delete_all), null: false, primary_key: true
    end

    create index(:anime_demographics, [:demographic_id])

    # ── Anime-Themes ──
    create table(:anime_themes, primary_key: false) do
      add :anime_id, references(:anime, on_delete: :delete_all), null: false, primary_key: true
      add :theme_id, references(:themes, on_delete: :delete_all), null: false, primary_key: true
    end

    create index(:anime_themes, [:theme_id])

    # ── Manga-Genre ──
    create table(:manga_genres, primary_key: false) do
      add :manga_id, references(:manga, on_delete: :delete_all), null: false, primary_key: true
      add :genre_id, references(:genres, on_delete: :delete_all), null: false, primary_key: true
    end

    create index(:manga_genres, [:genre_id])

    # ── Manga-Demographics ──
    create table(:manga_demographics, primary_key: false) do
      add :manga_id, references(:manga, on_delete: :delete_all), null: false, primary_key: true
      add :demographic_id, references(:demographics, on_delete: :delete_all), null: false, primary_key: true
    end

    create index(:manga_demographics, [:demographic_id])

    # ── Manga-Themes ──
    create table(:manga_themes, primary_key: false) do
      add :manga_id, references(:manga, on_delete: :delete_all), null: false, primary_key: true
      add :theme_id, references(:themes, on_delete: :delete_all), null: false, primary_key: true
    end

    create index(:manga_themes, [:theme_id])

    # ── Anime-Studios (with role) ──
    create table(:anime_studios, primary_key: false) do
      add :anime_id, references(:anime, on_delete: :delete_all), null: false, primary_key: true
      add :studio_id, references(:studios, on_delete: :delete_all), null: false, primary_key: true
      add :role, :string, size: 100, null: false, primary_key: true
    end

    create index(:anime_studios, [:studio_id])

    # ── Manga-Studios (with role) ──
    create table(:manga_studios, primary_key: false) do
      add :manga_id, references(:manga, on_delete: :delete_all), null: false, primary_key: true
      add :studio_id, references(:studios, on_delete: :delete_all), null: false, primary_key: true
      add :role, :string, size: 100, null: false, primary_key: true
    end

    create index(:manga_studios, [:studio_id])

    # ── Anime-Characters ──
    create table(:anime_characters, primary_key: false) do
      add :anime_id, references(:anime, on_delete: :delete_all), null: false, primary_key: true
      add :character_id, references(:characters, on_delete: :delete_all), null: false, primary_key: true
      add :role, :string, size: 50, null: false
    end

    create index(:anime_characters, [:character_id])

    # ── Manga-Characters ──
    create table(:manga_characters, primary_key: false) do
      add :manga_id, references(:manga, on_delete: :delete_all), null: false, primary_key: true
      add :character_id, references(:characters, on_delete: :delete_all), null: false, primary_key: true
      add :role, :string, size: 50, null: false
    end

    create index(:manga_characters, [:character_id])

    # ── Character Voice Actors ──
    create table(:character_voice_actors, primary_key: false) do
      add :character_id, references(:characters, on_delete: :delete_all), null: false, primary_key: true
      add :person_id, references(:people, on_delete: :delete_all), null: false, primary_key: true
      add :anime_id, references(:anime, on_delete: :delete_all), null: false, primary_key: true
      add :language, :string, size: 20, null: false, primary_key: true
    end

    create index(:character_voice_actors, [:person_id])
    create index(:character_voice_actors, [:anime_id])

    # ── Anime Staff ──
    create table(:anime_staff, primary_key: false) do
      add :anime_id, references(:anime, on_delete: :delete_all), null: false, primary_key: true
      add :person_id, references(:people, on_delete: :delete_all), null: false, primary_key: true
      add :position, :string, size: 100, null: false, primary_key: true
    end

    create index(:anime_staff, [:person_id])

    # ── Manga Staff ──
    create table(:manga_staff, primary_key: false) do
      add :manga_id, references(:manga, on_delete: :delete_all), null: false, primary_key: true
      add :person_id, references(:people, on_delete: :delete_all), null: false, primary_key: true
      add :position, :string, size: 100, null: false, primary_key: true
    end

    create index(:manga_staff, [:person_id])

    # ── Anime Relations (sequel, prequel, etc.) ──
    create table(:anime_relations) do
      add :anime_id, references(:anime, on_delete: :delete_all), null: false
      add :related_anime_id, references(:anime, on_delete: :delete_all), null: false
      add :relation_type, :string, size: 50, null: false
    end

    create unique_index(:anime_relations, [:anime_id, :related_anime_id, :relation_type])
    create index(:anime_relations, [:related_anime_id])

    # ── Manga Relations ──
    create table(:manga_relations) do
      add :manga_id, references(:manga, on_delete: :delete_all), null: false
      add :related_manga_id, references(:manga, on_delete: :delete_all), null: false
      add :relation_type, :string, size: 50, null: false
    end

    create unique_index(:manga_relations, [:manga_id, :related_manga_id, :relation_type])
    create index(:manga_relations, [:related_manga_id])

    # ── Anime-Manga Relations (adaptations) ──
    create table(:anime_manga_relations) do
      add :anime_id, references(:anime, on_delete: :delete_all), null: false
      add :manga_id, references(:manga, on_delete: :delete_all), null: false
      add :relation_type, :string, size: 50, null: false
    end

    create unique_index(:anime_manga_relations, [:anime_id, :manga_id, :relation_type])
  end
end
