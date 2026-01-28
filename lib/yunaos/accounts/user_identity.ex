defmodule Yunaos.Accounts.UserIdentity do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "users"
  schema "user_identities" do
    field :provider, :string
    field :provider_uid, :string
    field :provider_email, :string
    field :provider_name, :string

    belongs_to :user, Yunaos.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(identity, attrs) do
    identity
    |> cast(attrs, [:provider, :provider_uid, :provider_email, :provider_name, :user_id])
    |> validate_required([:provider, :provider_uid, :user_id])
    |> unique_constraint([:provider, :provider_uid])
  end
end
