defmodule Yunaos.Repo.Migrations.CreatePeopleAndCharacters do
  use Ecto.Migration

  def change do
    # ── People (voice actors, directors, writers, etc.) ──
    create table(:people) do
      add :mal_id, :integer
      add :name, :string, size: 200, null: false
      add :given_name, :string, size: 100
      add :family_name, :string, size: 100
      add :alternate_names, {:array, :text}, default: []

      add :birthday, :date
      add :website_url, :string, size: 500
      add :image_url, :string, size: 1000
      add :about, :text

      add :favorites_count, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:people, [:mal_id])

    # ── Characters ──
    create table(:characters) do
      add :mal_id, :integer
      add :name, :string, size: 200, null: false
      add :name_kanji, :string, size: 200
      add :nicknames, {:array, :text}, default: []

      add :about, :text
      add :image_url, :string, size: 1000

      add :favorites_count, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:characters, [:mal_id])
  end
end
