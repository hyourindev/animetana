defmodule Animetana.Accounts.UserAnimeList do
  @moduledoc """
  Schema for user anime list entries.
  Tracks which anime a user is watching, has completed, etc.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @statuses [:watching, :completed, :on_hold, :dropped, :plan_to_watch]

  @primary_key {:id, :id, autogenerate: true}
  @schema_prefix "users"

  schema "user_anime_lists" do
    belongs_to :user, Animetana.Accounts.User
    belongs_to :anime, Animetana.Contents.Anime, foreign_key: :anime_id

    # Status
    field :status, Ecto.Enum, values: @statuses

    # Progress
    field :score, :integer
    field :progress, :integer, default: 0

    # Dates
    field :start_date, :date
    field :finish_date, :date

    # Notes & Tags
    field :notes, :string
    field :tags, {:array, :string}, default: []

    # Rewatch
    field :is_rewatching, :boolean, default: false
    field :rewatch_count, :integer, default: 0
    field :rewatch_value, :integer

    # Flags
    field :is_favorite, :boolean, default: false
    field :is_private, :boolean, default: false

    # Priority (1-5, for plan_to_watch)
    field :priority, :integer

    # Custom lists (JSONB)
    field :custom_lists, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for adding an anime to a user's list.
  """
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [
      :user_id, :anime_id, :status, :score, :progress,
      :start_date, :finish_date, :notes, :tags,
      :is_rewatching, :rewatch_count, :rewatch_value,
      :is_favorite, :is_private, :priority, :custom_lists
    ])
    |> validate_required([:user_id, :anime_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:score, 1..10)
    |> validate_number(:progress, greater_than_or_equal_to: 0)
    |> validate_inclusion(:priority, 1..5)
    |> validate_number(:rewatch_count, greater_than_or_equal_to: 0)
    |> validate_inclusion(:rewatch_value, 1..5)
    |> validate_length(:notes, max: 2000)
    |> unique_constraint([:user_id, :anime_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:anime_id)
  end

  @doc """
  Changeset for updating status only (quick actions).
  """
  def status_changeset(entry, attrs) do
    entry
    |> cast(attrs, [:status])
    |> validate_required([:status])
    |> validate_inclusion(:status, @statuses)
    |> maybe_set_dates()
  end

  @doc """
  Changeset for incrementing progress.
  """
  def progress_changeset(entry, attrs) do
    entry
    |> cast(attrs, [:progress])
    |> validate_required([:progress])
    |> validate_number(:progress, greater_than_or_equal_to: 0)
  end

  @doc """
  Changeset for updating score only.
  """
  def score_changeset(entry, attrs) do
    entry
    |> cast(attrs, [:score])
    |> validate_inclusion(:score, 1..10)
  end

  @doc """
  Returns all valid statuses.
  """
  def statuses, do: @statuses

  @doc """
  Returns the status as a human-readable string.
  """
  def format_status(:watching), do: "Watching"
  def format_status(:completed), do: "Completed"
  def format_status(:on_hold), do: "On Hold"
  def format_status(:dropped), do: "Dropped"
  def format_status(:plan_to_watch), do: "Plan to Watch"
  def format_status(_), do: "Unknown"

  @doc """
  Returns the status as a localized string.
  """
  def format_status(:watching, "ja"), do: "視聴中"
  def format_status(:completed, "ja"), do: "視聴済み"
  def format_status(:on_hold, "ja"), do: "中断中"
  def format_status(:dropped, "ja"), do: "中止"
  def format_status(:plan_to_watch, "ja"), do: "視聴予定"
  def format_status(status, _locale), do: format_status(status)

  # Automatically set start_date when starting to watch, finish_date when completed
  defp maybe_set_dates(changeset) do
    case get_change(changeset, :status) do
      :watching ->
        if is_nil(get_field(changeset, :start_date)) do
          put_change(changeset, :start_date, Date.utc_today())
        else
          changeset
        end

      :completed ->
        if is_nil(get_field(changeset, :finish_date)) do
          put_change(changeset, :finish_date, Date.utc_today())
        else
          changeset
        end

      _ ->
        changeset
    end
  end
end
