defmodule Animetana.Repo.Migrations.AddCharacterEnrichmentTracking do
  use Ecto.Migration

  def change do
    alter table(:characters, prefix: "contents") do
      add :enrichment_status, :integer, default: 0
      add :enrichment_error, :text
      add :enriched_at, :"timestamp(0)"
    end

    create index(:characters, [:enrichment_status], prefix: "contents",
           where: "enrichment_status < 7 AND deleted_at IS NULL")
  end
end
