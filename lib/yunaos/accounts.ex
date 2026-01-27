defmodule Yunaos.Accounts do
  alias Yunaos.Repo
  alias Yunaos.Accounts.{User, UserToken, UserNotifier, UserIdentity}

  ## User registration

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false)
  end

  ## OAuth registration

  def find_or_create_user_from_oauth(%Ueberauth.Auth{} = auth) do
    provider = to_string(auth.provider)
    uid = to_string(auth.uid)
    email = auth.info.email && String.downcase(auth.info.email)
    name = auth.info.name || email

    case get_identity_by_provider(provider, uid) do
      %UserIdentity{} = identity ->
        {:ok, Repo.preload(identity, :user).user}

      nil ->
        Repo.transaction(fn ->
          user = if email, do: get_user_by_email(email)

          user =
            case user do
              %User{} = existing ->
                existing

              nil ->
                identifier = generate_unique_identifier(name)

                %User{}
                |> User.oauth_registration_changeset(%{
                  name: name,
                  identifier: identifier,
                  email: email
                })
                |> Repo.insert!()
            end

          %UserIdentity{}
          |> UserIdentity.changeset(%{
            provider: provider,
            provider_uid: uid,
            provider_email: email,
            provider_name: name,
            user_id: user.id
          })
          |> Repo.insert!()

          user
        end)
    end
  end

  def get_identity_by_provider(provider, uid) do
    Repo.get_by(UserIdentity, provider: provider, provider_uid: uid)
  end

  defp generate_unique_identifier(name) do
    base =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9_]/, "_")
      |> String.replace(~r/_+/, "_")
      |> String.trim("_")
      |> String.slice(0, 15)

    base = if String.length(base) < 3, do: "user", else: base

    if get_user_by_identifier(base) == nil do
      base
    else
      suffix = :rand.uniform(9999)
      "#{String.slice(base, 0, 15)}_#{suffix}"
    end
  end

  ## User lookup

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: String.downcase(email))
  end

  def get_user_by_identifier(identifier) when is_binary(identifier) do
    Repo.get_by(User, identifier: String.downcase(identifier))
  end

  def get_user_by_email_or_identifier_and_password(login, password)
      when is_binary(login) and is_binary(password) do
    user = get_user_by_login(login)
    if User.valid_password?(user, password), do: user
  end

  defp get_user_by_login(login) do
    login = String.downcase(login)

    if String.contains?(login, "@") do
      Repo.get_by(User, email: login)
    else
      Repo.get_by(User, identifier: login)
    end
  end

  def get_user!(id), do: Repo.get!(User, id)

  def get_user(id), do: Repo.get(User, id)

  ## Session tokens

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Email confirmation

  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <-
           Repo.transaction(fn ->
             user = user |> User.confirm_changeset() |> Repo.update!()
             Repo.delete_all(UserToken.by_user_and_contexts_query(user, ["confirm"]))
             %{user: user}
           end) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  ## Password reset

  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Password update (while logged in)

  def update_user_password(user, current_password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(current_password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Email change

  def deliver_user_update_email_instructions(%User{} = user, _current_email, update_email_url_fun) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change_email")
    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  def update_user_email(user, token) do
    context = "change_email"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %{user: _user, sent_to: email} <- Repo.one(query) do
      Ecto.Multi.new()
      |> Ecto.Multi.update(:user, User.email_changeset(user, %{email: email}))
      |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
      |> Repo.transaction()
      |> case do
        {:ok, %{user: user}} -> {:ok, user}
        {:error, :user, changeset, _} -> {:error, changeset}
      end
    else
      _ -> :error
    end
  end

  ## Change helpers for forms

  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs)
  end

  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end
end
