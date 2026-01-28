defmodule Yunaos.Accounts.UserToken do
  use Ecto.Schema
  import Ecto.Query

  @hash_algorithm :sha256
  @rand_size 32

  @session_validity_in_days 60
  @confirm_validity_in_days 7
  @reset_password_validity_in_days 1
  @change_email_validity_in_days 7

  @schema_prefix "users"
  schema "user_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string

    belongs_to :user, Yunaos.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %__MODULE__{token: token, context: "session", user_id: user.id}}
  end

  def verify_session_token_query(token) do
    query =
      from t in __MODULE__,
        where: t.token == ^token and t.context == "session",
        where: t.inserted_at > ago(@session_validity_in_days, "day"),
        join: u in assoc(t, :user),
        select: u

    {:ok, query}
  end

  def build_email_token(user, context) do
    build_hashed_token(user, context, user.email)
  end

  defp build_hashed_token(user, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %__MODULE__{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       user_id: user.id
     }}
  end

  def verify_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        days = days_for_context(context)

        query =
          from t in __MODULE__,
            where: t.token == ^hashed_token and t.context == ^context,
            where: t.inserted_at > ago(^days, "day"),
            join: u in assoc(t, :user),
            select: u

        {:ok, query}

      :error ->
        :error
    end
  end

  def verify_change_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from t in __MODULE__,
            where: t.token == ^hashed_token and t.context == ^context,
            where: t.inserted_at > ago(@change_email_validity_in_days, "day"),
            join: u in assoc(t, :user),
            select: %{user: u, sent_to: t.sent_to}

        {:ok, query}

      :error ->
        :error
    end
  end

  defp days_for_context("confirm"), do: @confirm_validity_in_days
  defp days_for_context("reset_password"), do: @reset_password_validity_in_days
  defp days_for_context("change_email"), do: @change_email_validity_in_days

  def by_user_and_contexts_query(user, :all) do
    from t in __MODULE__, where: t.user_id == ^user.id
  end

  def by_user_and_contexts_query(user, contexts) when is_list(contexts) do
    from t in __MODULE__, where: t.user_id == ^user.id and t.context in ^contexts
  end

  def by_token_and_context_query(token, context) do
    from t in __MODULE__, where: t.token == ^token and t.context == ^context
  end
end
