defmodule Yunaos.Repo.Migrations.CreateTaxonomyTables do
  use Ecto.Migration

  def change do
    create table(:genres) do
      add :mal_id, :integer, null: false
      add :name, :string, size: 100, null: false
      add :type, :string, size: 20, null: false
      add :description, :text

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:genres, [:mal_id])
    create unique_index(:genres, [:name])

    create table(:demographics) do
      add :mal_id, :integer, null: false
      add :name, :string, size: 100, null: false
      add :type, :string, size: 20, null: false
      add :description, :text

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:demographics, [:mal_id])
    create unique_index(:demographics, [:name])

    create table(:themes) do
      add :mal_id, :integer, null: false
      add :name, :string, size: 100, null: false
      add :type, :string, size: 20, null: false
      add :description, :text

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:themes, [:mal_id])
    create unique_index(:themes, [:name])

    create table(:studios) do
      add :mal_id, :integer
      add :name, :string, size: 200, null: false
      add :type, :string, size: 50, null: false
      add :established, :date
      add :website_url, :string, size: 500
      add :about, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:studios, [:mal_id])
  end
end
