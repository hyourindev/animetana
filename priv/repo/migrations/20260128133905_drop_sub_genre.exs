defmodule Yunaos.Repo.Migrations.DropSubGenres do
  use Ecto.Migration

  def up do
    # Drop junction tables first (they reference sub_genres)
    drop_if_exists table(:manga_sub_genres)
    drop_if_exists table(:anime_sub_genres)
    drop_if_exists table(:genre_sub_genres)

    # Drop the main sub_genres table
    drop_if_exists table(:sub_genres)
  end

  def down do
    # Recreate sub_genres table
    create table(:sub_genres) do
      add :name, :string, size: 100, null: false
      add :name_ja, :string, size: 100
      add :description, :text
      add :description_ja, :text
      add :inserted_at, :naive_datetime, null: false
    end

    create unique_index(:sub_genres, [:name])

    # Recreate junction tables
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
  end
end