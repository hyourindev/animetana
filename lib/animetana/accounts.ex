defmodule Animetana.Accounts do
  import Ecto.Query

  alias Animetana.Repo
  alias Animetana.Accounts.{User, UserToken, UserNotifier, UserIdentity, UserAnimeList}
  alias Animetana.Contents.Anime

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

  ## Onboarding (region selection)

  @doc """
  Returns true if user has completed onboarding.
  """
  def onboarding_completed?(%User{} = user), do: User.onboarding_completed?(user)

  @doc """
  Completes user onboarding by setting their region.
  """
  def complete_onboarding(%User{} = user, attrs) do
    user
    |> User.onboarding_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns a changeset for onboarding form.
  """
  def change_user_onboarding(%User{} = user, attrs \\ %{}) do
    User.onboarding_changeset(user, attrs)
  end

  ## User profile

  @doc """
  Gets a user by identifier (username) or display name, raises if not found.
  Tries identifier first, then falls back to display name.
  """
  def get_user_by_identifier!(slug) when is_binary(slug) do
    # Try identifier first (case-insensitive)
    case Repo.get_by(User, identifier: String.downcase(slug)) do
      %User{} = user ->
        user

      nil ->
        # Fall back to display name (case-insensitive)
        User
        |> where([u], fragment("LOWER(?)", u.name) == ^String.downcase(slug))
        |> Repo.one!()
    end
  end

  @doc """
  Updates a user's profile.
  """
  def update_user_profile(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns a changeset for tracking user profile changes.
  """
  def change_user_profile(%User{} = user, attrs \\ %{}) do
    User.profile_changeset(user, attrs)
  end

  @doc """
  Updates a user's preferences.
  """
  def update_user_preferences(%User{} = user, attrs) do
    user
    |> User.preferences_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns a changeset for tracking user preferences changes.
  """
  def change_user_preferences(%User{} = user, attrs \\ %{}) do
    User.preferences_changeset(user, attrs)
  end

  @doc """
  Updates a user's privacy settings.
  """
  def update_user_privacy(%User{} = user, attrs) do
    user
    |> User.privacy_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns a changeset for tracking user privacy changes.
  """
  def change_user_privacy(%User{} = user, attrs \\ %{}) do
    User.privacy_changeset(user, attrs)
  end

  ## Privacy checks

  @doc """
  Returns true if the viewer can view the profile.
  A private profile can only be viewed by the owner.
  """
  def can_view_profile?(%User{} = profile_user, viewer) do
    cond do
      # Owner can always view their own profile
      viewer && viewer.id == profile_user.id -> true
      # Private profiles can't be viewed by others
      profile_user.is_private -> false
      # Public profiles can be viewed by anyone
      true -> true
    end
  end

  @doc """
  Returns true if the viewer can see the user's statistics.
  """
  def can_view_statistics?(%User{} = profile_user, viewer) do
    cond do
      viewer && viewer.id == profile_user.id -> true
      profile_user.is_private -> false
      not profile_user.show_statistics -> false
      true -> true
    end
  end

  @doc """
  Returns true if the viewer can see the user's activity.
  """
  def can_view_activity?(%User{} = profile_user, viewer) do
    cond do
      viewer && viewer.id == profile_user.id -> true
      profile_user.is_private -> false
      not profile_user.show_activity -> false
      true -> true
    end
  end

  ## User Anime List

  @doc """
  Gets a user's anime list entry for a specific anime.
  Returns nil if not found.
  """
  def get_user_anime_entry(user_id, anime_id) do
    Repo.get_by(UserAnimeList, user_id: user_id, anime_id: anime_id)
  end

  @doc """
  Gets a user's anime list entry by ID.
  """
  def get_user_anime_entry!(id), do: Repo.get!(UserAnimeList, id)

  @doc """
  Gets a user's anime list entry by ID, preloading anime.
  """
  def get_user_anime_entry_with_anime!(id) do
    UserAnimeList
    |> Repo.get!(id)
    |> Repo.preload(:anime)
  end

  @doc """
  Creates or updates a user's anime list entry.
  """
  def upsert_anime_entry(%User{} = user, anime_id, attrs) do
    case get_user_anime_entry(user.id, anime_id) do
      nil ->
        %UserAnimeList{}
        |> UserAnimeList.changeset(Map.merge(attrs, %{user_id: user.id, anime_id: anime_id}))
        |> Repo.insert()

      entry ->
        entry
        |> UserAnimeList.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Adds an anime to a user's list with a specific status.
  """
  def add_anime_to_list(%User{} = user, anime_id, status) when is_atom(status) do
    upsert_anime_entry(user, anime_id, %{status: status})
  end

  @doc """
  Updates the status of an anime list entry.
  """
  def update_anime_status(%UserAnimeList{} = entry, status) do
    entry
    |> UserAnimeList.status_changeset(%{status: status})
    |> Repo.update()
  end

  @doc """
  Updates the score of an anime list entry.
  """
  def update_anime_score(%UserAnimeList{} = entry, score) do
    entry
    |> UserAnimeList.score_changeset(%{score: score})
    |> Repo.update()
  end

  @doc """
  Increments the progress of an anime list entry by 1.
  """
  def increment_anime_progress(%UserAnimeList{} = entry) do
    new_progress = (entry.progress || 0) + 1

    entry
    |> UserAnimeList.progress_changeset(%{progress: new_progress})
    |> Repo.update()
  end

  @doc """
  Sets the progress of an anime list entry.
  """
  def set_anime_progress(%UserAnimeList{} = entry, progress) do
    entry
    |> UserAnimeList.progress_changeset(%{progress: progress})
    |> Repo.update()
  end

  @doc """
  Updates a full anime list entry.
  """
  def update_anime_entry(%UserAnimeList{} = entry, attrs) do
    entry
    |> UserAnimeList.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an anime list entry.
  """
  def delete_anime_entry(%UserAnimeList{} = entry) do
    Repo.delete(entry)
  end

  @doc """
  Returns a changeset for anime list entry forms.
  """
  def change_anime_entry(%UserAnimeList{} = entry, attrs \\ %{}) do
    UserAnimeList.changeset(entry, attrs)
  end

  @doc """
  Lists a user's anime entries, with optional filters.

  Options:
    - :status - filter by status (atom or list of atoms)
    - :sort - sort field (:updated_at, :score, :progress, :title)
    - :order - sort direction (:asc, :desc)
    - :limit - limit number of results
    - :offset - offset for pagination
    - :preload_anime - whether to preload anime data (default: true)
  """
  def list_user_anime(%User{} = user, opts \\ []) do
    status = Keyword.get(opts, :status)
    sort = Keyword.get(opts, :sort, :updated_at)
    order = Keyword.get(opts, :order, :desc)
    limit = Keyword.get(opts, :limit)
    offset = Keyword.get(opts, :offset, 0)
    preload_anime = Keyword.get(opts, :preload_anime, true)

    query =
      from ual in UserAnimeList,
        where: ual.user_id == ^user.id

    query =
      case status do
        nil -> query
        statuses when is_list(statuses) -> from q in query, where: q.status in ^statuses
        status -> from q in query, where: q.status == ^status
      end

    query = apply_anime_list_sort(query, sort, order)

    query =
      if limit do
        from q in query, limit: ^limit, offset: ^offset
      else
        query
      end

    results = Repo.all(query)

    if preload_anime do
      Repo.preload(results, :anime)
    else
      results
    end
  end

  @doc """
  Counts a user's anime entries by status.
  Returns a map like %{watching: 5, completed: 20, ...}
  """
  def count_user_anime_by_status(%User{} = user) do
    from(ual in UserAnimeList,
      where: ual.user_id == ^user.id,
      group_by: ual.status,
      select: {ual.status, count(ual.id)}
    )
    |> Repo.all()
    |> Enum.into(%{})
  end

  @doc """
  Returns the total count of anime in a user's list.
  """
  def count_user_anime(%User{} = user, opts \\ []) do
    status = Keyword.get(opts, :status)

    query =
      from ual in UserAnimeList,
        where: ual.user_id == ^user.id

    query =
      case status do
        nil -> query
        statuses when is_list(statuses) -> from q in query, where: q.status in ^statuses
        status -> from q in query, where: q.status == ^status
      end

    Repo.aggregate(query, :count)
  end

  defp apply_anime_list_sort(query, :updated_at, order) do
    from q in query, order_by: [{^order, q.updated_at}]
  end

  defp apply_anime_list_sort(query, :score, order) do
    from q in query, order_by: [{^order, q.score}, {^order, q.updated_at}]
  end

  defp apply_anime_list_sort(query, :progress, order) do
    from q in query, order_by: [{^order, q.progress}, {^order, q.updated_at}]
  end

  defp apply_anime_list_sort(query, :title, order) do
    from q in query,
      join: a in Anime, on: a.id == q.anime_id,
      order_by: [{^order, coalesce(a.title_en, a.title_romaji)}, {^order, q.updated_at}]
  end

  defp apply_anime_list_sort(query, _sort, order) do
    from q in query, order_by: [{^order, q.updated_at}]
  end
end
