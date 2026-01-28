defmodule Yunaos.Repo.Migrations.DropTaxonomyNameUniqueIndexes do
  use Ecto.Migration

  @moduledoc """
  Drop unique indexes on `name` for genres, demographics, and themes.

  The Jikan API returns entries with the same name but different mal_ids
  (e.g., "Suspense" exists as mal_id 45 for manga and mal_id 41 for both).
  The mal_id unique index is the correct identity constraint.
  """

  def change do
    drop_if_exists unique_index(:genres, [:name])
    drop_if_exists unique_index(:demographics, [:name])
    drop_if_exists unique_index(:themes, [:name])
  end
end
