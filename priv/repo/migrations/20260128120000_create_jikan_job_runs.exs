defmodule Yunaos.Repo.Migrations.CreateJikanJobRuns do
  use Ecto.Migration

  def change do
    create table(:jikan_job_runs) do
      add :job_id, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime
      add :error_message, :text

      timestamps()
    end

    create unique_index(:jikan_job_runs, [:job_id])
    create index(:jikan_job_runs, [:status])
  end
end
