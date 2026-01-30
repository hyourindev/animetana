defmodule Animetana.Accounts.User do
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

    # Region: :global or :jp - determines which community the user belongs to
    field :region, Ecto.Enum, values: [:global, :jp], default: :global

    # Onboarding: nil means user hasn't completed setup (region selection)
    field :onboarding_completed_at, :utc_datetime

    # Profile
    field :bio, :string
    field :avatar_url, :string
    field :banner_url, :string
    field :location, :string
    field :website_url, :string
    field :birthday, :date
    field :gender, :string

    # Preferences
    field :timezone, :string, default: "UTC"
    field :language, :string, default: "en"
    field :theme, Ecto.Enum, values: [:light, :dark, :system], default: :dark
    field :title_language, Ecto.Enum, values: [:english, :romaji, :native], default: :romaji

    # Privacy
    field :is_private, :boolean, default: false
    field :show_adult_content, :boolean, default: false
    field :allow_friend_requests, :boolean, default: true
    field :show_activity, :boolean, default: true
    field :show_statistics, :boolean, default: true

    # Stats (read-only, managed by DB triggers)
    field :anime_count, :integer, default: 0
    field :manga_count, :integer, default: 0
    field :episodes_watched, :integer, default: 0
    field :chapters_read, :integer, default: 0
    field :days_watched, :decimal
    field :days_read, :decimal
    field :mean_anime_score, :decimal
    field :mean_manga_score, :decimal
    field :followers_count, :integer, default: 0
    field :following_count, :integer, default: 0

    has_many :user_identities, Animetana.Accounts.UserIdentity

    timestamps(type: :utc_datetime)
  end

  @doc """
  Returns true if the user has completed onboarding (selected their region).
  """
  def onboarding_completed?(%__MODULE__{onboarding_completed_at: nil}), do: false
  def onboarding_completed?(%__MODULE__{}), do: true

  def registration_changeset(user, attrs, opts \\ []) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    user
    |> cast(attrs, [:name, :identifier, :email, :password, :region])
    |> validate_name()
    |> validate_identifier()
    |> validate_email()
    |> validate_password(opts)
    |> validate_required([:region])
    |> validate_inclusion(:region, [:global, :jp])
    |> put_change(:onboarding_completed_at, now)
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

  @doc """
  Changeset for completing onboarding (name, identifier, region).
  Used for OAuth users who need to set their profile after signing in.
  """
  def onboarding_changeset(user, attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    user
    |> cast(attrs, [:name, :identifier, :region])
    |> validate_name()
    |> validate_identifier()
    |> validate_required([:region])
    |> validate_inclusion(:region, [:global, :jp])
    |> put_change(:onboarding_completed_at, now)
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

  @doc """
  Changeset for updating user profile fields.
  """
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :bio, :avatar_url, :banner_url, :location, :website_url, :birthday, :gender])
    |> validate_name()
    |> validate_length(:bio, max: 500)
    |> validate_length(:location, max: 100)
    |> validate_url(:avatar_url)
    |> validate_url(:banner_url)
    |> validate_url(:website_url)
    |> validate_inclusion(:gender, ["male", "female", "non-binary", "other", "prefer_not_to_say", nil])
  end

  @doc """
  Changeset for updating user preferences.
  """
  def preferences_changeset(user, attrs) do
    user
    |> cast(attrs, [:timezone, :language, :theme, :title_language])
    |> validate_length(:timezone, max: 50)
    |> validate_inclusion(:language, ["en", "ja"])
  end

  @doc """
  Changeset for updating user privacy settings.
  """
  def privacy_changeset(user, attrs) do
    user
    |> cast(attrs, [:is_private, :show_adult_content, :allow_friend_requests, :show_activity, :show_statistics])
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      case URI.parse(value) do
        %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and not is_nil(host) ->
          []

        _ ->
          [{field, "must be a valid URL"}]
      end
    end)
  end

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
    |> unsafe_validate_unique(:identifier, Animetana.Repo)
    |> unique_constraint(:identifier)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> update_change(:email, &String.downcase/1)
    |> unsafe_validate_unique(:email, Animetana.Repo)
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
