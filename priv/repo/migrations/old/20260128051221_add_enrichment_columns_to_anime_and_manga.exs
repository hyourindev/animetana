defmodule Yunaos.Repo.Migrations.AddEnrichmentColumnsToAnimeAndManga do
  use Ecto.Migration

  def change do
    alter table(:anime) do
      add_if_not_exists :opening_themes, {:array, :text}, default: []
      add_if_not_exists :ending_themes, {:array, :text}, default: []
      add_if_not_exists :external_links, :jsonb, default: "[]"
      add_if_not_exists :streaming_links, :jsonb, default: "[]"
    end
  end
end
