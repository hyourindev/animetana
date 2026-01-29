defmodule Animetana.Repo.Migrations.DropDemographics do
  use Ecto.Migration

  def up do
    # Drop junction tables first (foreign key constraints)
    drop_if_exists table(:anime_demographics, prefix: "contents")
    drop_if_exists table(:manga_demographics, prefix: "contents")

    # Drop main demographics table
    drop_if_exists table(:demographics, prefix: "contents")
  end

  def down do
    # Recreate demographics table
    execute """
    CREATE TABLE contents.demographics (
      id BIGSERIAL PRIMARY KEY,
      mal_id INTEGER,
      anilist_id INTEGER,
      name_en VARCHAR(100) NOT NULL,
      name_ja VARCHAR(100),
      name_romaji VARCHAR(100),
      description_en TEXT,
      description_ja TEXT,
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP(0) NOT NULL DEFAULT NOW()
    )
    """

    # Recreate junction tables
    execute """
    CREATE TABLE contents.anime_demographics (
      anime_id BIGINT NOT NULL REFERENCES contents.anime(id) ON DELETE CASCADE,
      demographic_id BIGINT NOT NULL REFERENCES contents.demographics(id) ON DELETE CASCADE,
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      PRIMARY KEY (anime_id, demographic_id)
    )
    """

    execute """
    CREATE TABLE contents.manga_demographics (
      manga_id BIGINT NOT NULL REFERENCES contents.manga(id) ON DELETE CASCADE,
      demographic_id BIGINT NOT NULL REFERENCES contents.demographics(id) ON DELETE CASCADE,
      inserted_at TIMESTAMP(0) NOT NULL DEFAULT NOW(),
      PRIMARY KEY (manga_id, demographic_id)
    )
    """
  end
end
