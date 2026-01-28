defmodule Yunaos.Repo.Migrations.CreateUserLists do
  use Ecto.Migration

  def change do
    # ── Status Enums ──
    execute(
      "CREATE TYPE anime_list_status AS ENUM ('watching', 'completed', 'on_hold', 'dropped', 'plan_to_watch')",
      "DROP TYPE IF EXISTS anime_list_status"
    )

    execute(
      "CREATE TYPE manga_list_status AS ENUM ('reading', 'completed', 'on_hold', 'dropped', 'plan_to_read')",
      "DROP TYPE IF EXISTS manga_list_status"
    )

    # ── User Anime Lists ──
    create table(:user_anime_lists) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :anime_id, references(:anime, on_delete: :delete_all), null: false

      add :status, :anime_list_status, null: false
      add :score, :integer
      add :progress, :integer, default: 0

      add :start_date, :date
      add :finish_date, :date

      add :notes, :text
      add :is_favorite, :boolean, default: false
      add :is_rewatching, :boolean, default: false
      add :rewatch_count, :integer, default: 0
      add :rewatch_value, :integer

      add :is_private, :boolean, default: false
      add :tags, {:array, :text}, default: []

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_anime_lists, [:user_id, :anime_id])
    create index(:user_anime_lists, [:user_id, :status])
    create index(:user_anime_lists, [:anime_id])
    create index(:user_anime_lists, [:user_id, :updated_at])

    # ── User Manga Lists ──
    create table(:user_manga_lists) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :manga_id, references(:manga, on_delete: :delete_all), null: false

      add :status, :manga_list_status, null: false
      add :score, :integer
      add :progress, :integer, default: 0
      add :progress_volumes, :integer, default: 0

      add :start_date, :date
      add :finish_date, :date

      add :notes, :text
      add :is_favorite, :boolean, default: false
      add :is_rereading, :boolean, default: false
      add :reread_count, :integer, default: 0
      add :reread_value, :integer

      add :is_private, :boolean, default: false
      add :tags, {:array, :text}, default: []

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_manga_lists, [:user_id, :manga_id])
    create index(:user_manga_lists, [:user_id, :status])
    create index(:user_manga_lists, [:manga_id])

    # ── User Episode Progress ──
    create table(:user_episode_progress) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :episode_id, references(:episodes, on_delete: :delete_all), null: false
      add :anime_id, references(:anime, on_delete: :delete_all), null: false

      add :score, :integer
      add :watched_at, :utc_datetime

      add :progress_seconds, :integer, default: 0
      add :total_seconds, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_episode_progress, [:user_id, :episode_id])

    # ── User Chapter Progress ──
    create table(:user_chapter_progress) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :chapter_id, references(:chapters, on_delete: :delete_all), null: false
      add :manga_id, references(:manga, on_delete: :delete_all), null: false

      add :score, :integer
      add :read_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_chapter_progress, [:user_id, :chapter_id])

    # ── User Favorites (polymorphic) ──
    create table(:user_favorites) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :favorable_type, :string, size: 20, null: false
      add :favorable_id, :bigint, null: false
      add :display_order, :integer, default: 0

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:user_favorites, [:user_id, :favorable_type, :favorable_id])
  end
end
