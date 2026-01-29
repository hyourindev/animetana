defmodule Animetana.Repo.Migrations.AddEnrichmentTracking do
  use Ecto.Migration

  def change do
    # Add enrichment tracking to anime table
    alter table(:anime, prefix: "contents") do
      # Bitmask: 1=synopsis_ja, 2=background_en, 4=background_ja
      add :enrichment_status, :integer, default: 0
      add :enrichment_error, :text
      add :enriched_at, :"timestamp(0)"
    end

    # Add enrichment tracking to manga table
    alter table(:manga, prefix: "contents") do
      add :enrichment_status, :integer, default: 0
      add :enrichment_error, :text
      add :enriched_at, :"timestamp(0)"
    end

    # Indexes for efficient querying of unenriched entries
    create index(:anime, [:enrichment_status], prefix: "contents",
           where: "enrichment_status < 7 AND deleted_at IS NULL")
    create index(:manga, [:enrichment_status], prefix: "contents",
           where: "enrichment_status < 7 AND deleted_at IS NULL")
  end
end
