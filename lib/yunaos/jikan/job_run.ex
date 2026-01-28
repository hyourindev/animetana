defmodule Yunaos.Jikan.JobRun do
  use Ecto.Schema
  import Ecto.Changeset

  schema "jikan_job_runs" do
    field :job_id, :string
    field :status, :string, default: "pending"
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :error_message, :string

    timestamps()
  end

  def changeset(job_run, attrs) do
    job_run
    |> cast(attrs, [:job_id, :status, :started_at, :completed_at, :error_message])
    |> validate_required([:job_id, :status])
    |> validate_inclusion(:status, ~w(pending running completed failed skipped))
    |> unique_constraint(:job_id)
  end
end
