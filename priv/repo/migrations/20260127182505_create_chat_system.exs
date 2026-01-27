defmodule Yunaos.Repo.Migrations.CreateChatSystem do
  use Ecto.Migration

  def change do
    # ── Chat Rooms ──
    create table(:chat_rooms, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")

      add :content_type, :string, size: 20, null: false
      add :content_id, :bigint
      add :parent_content_id, :bigint

      add :title, :string, size: 500, null: false
      add :description, :text
      add :is_active, :boolean, default: true
      add :is_archived, :boolean, default: false

      add :max_participants, :integer, default: 1000
      add :is_public, :boolean, default: true
      add :requires_registration, :boolean, default: false

      add :is_moderated, :boolean, default: true
      add :slow_mode_duration, :integer, default: 0

      add :message_count, :integer, default: 0
      add :active_participants, :integer, default: 0
      add :total_participants, :integer, default: 0
      add :last_message_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:chat_rooms, [:content_type, :content_id])

    # ── Chat Messages ──
    create table(:chat_messages, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :chat_room_id, references(:chat_rooms, type: :uuid, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :nilify_all)

      add :content, :text, null: false
      add :message_type, :string, size: 20, default: "text"

      add :is_deleted, :boolean, default: false
      add :is_edited, :boolean, default: false
      add :deleted_at, :utc_datetime
      add :deleted_reason, :text
      add :edit_count, :integer, default: 0

      add :is_flagged, :boolean, default: false
      add :flagged_reason, :text

      add :reply_to_message_id, references(:chat_messages, type: :uuid, on_delete: :nilify_all)

      add :reactions, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:chat_messages, [:chat_room_id, :inserted_at])
    create index(:chat_messages, [:user_id, :inserted_at])

    # ── Chat Participants ──
    create table(:chat_participants, primary_key: false) do
      add :chat_room_id, references(:chat_rooms, type: :uuid, on_delete: :delete_all), null: false, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), null: false, primary_key: true

      add :joined_at, :utc_datetime, default: fragment("now()")
      add :last_seen_at, :utc_datetime, default: fragment("now()")
      add :last_message_read_at, :utc_datetime

      add :role, :string, size: 20, default: "member"
      add :is_muted, :boolean, default: false
      add :is_banned, :boolean, default: false
      add :muted_until, :utc_datetime
      add :banned_until, :utc_datetime
    end

    create index(:chat_participants, [:user_id, :last_seen_at])
  end
end
