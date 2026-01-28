defmodule Yunaos.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "users"
  schema "users" do
    field :name, :string
    field :identifier, :string
    field :email, :string
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :password, :string, virtual: true, redact: true

    has_many :user_identities, Yunaos.Accounts.UserIdentity

    timestamps(type: :utc_datetime)
  end

  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:name, :identifier, :email, :password])
    |> validate_name()
    |> validate_identifier()
    |> validate_email()
    |> validate_password(opts)
  end

  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  def oauth_registration_changeset(user, attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    user
    |> cast(attrs, [:name, :identifier, :email])
    |> validate_name()
    |> validate_identifier()
    |> validate_email()
    |> put_change(:confirmed_at, now)
  end

  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  def valid_password?(%__MODULE__{hashed_password: hashed}, password)
      when is_binary(hashed) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  def has_password?(%__MODULE__{hashed_password: hashed}), do: is_binary(hashed)

  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  defp validate_name(changeset) do
    changeset
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 50)
  end

  defp validate_identifier(changeset) do
    changeset
    |> validate_required([:identifier])
    |> validate_length(:identifier, min: 3, max: 20)
    |> validate_format(:identifier, ~r/^[a-zA-Z0-9_]+$/,
      message: "only letters, numbers, and underscores allowed"
    )
    |> update_change(:identifier, &String.downcase/1)
    |> unsafe_validate_unique(:identifier, Yunaos.Repo)
    |> unique_constraint(:identifier)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> update_change(:email, &String.downcase/1)
    |> unsafe_validate_unique(:email, Yunaos.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end
end
