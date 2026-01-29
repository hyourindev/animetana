defmodule AnimetanaWeb.UserAuth do
  use AnimetanaWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias Animetana.Accounts
  alias AnimetanaWeb.Plugs.Locale

  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_Animetana_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  def log_in_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)
    user_return_to = get_session(conn, :user_return_to)
    locale = get_locale(conn)

    # Redirect to onboarding if not completed, otherwise to return path or home
    redirect_to =
      if Accounts.onboarding_completed?(user) do
        user_return_to || signed_in_path(conn, locale)
      else
        ~p"/#{locale}/onboarding/region"
      end

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: redirect_to)
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params), do: conn

  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_user_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      AnimetanaWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      locale = get_locale(conn)

      conn
      |> redirect(to: signed_in_path(conn, locale))
      |> halt()
    else
      conn
    end
  end

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      locale = get_locale(conn)

      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/#{locale}/users/log_in")
      |> halt()
    end
  end

  @doc """
  Requires user to have completed onboarding (region selection).
  Redirects to onboarding if not completed.
  """
  def require_onboarding_completed(conn, _opts) do
    user = conn.assigns[:current_user]

    cond do
      is_nil(user) ->
        # Not logged in, let require_authenticated_user handle it
        conn

      Accounts.onboarding_completed?(user) ->
        conn

      true ->
        locale = get_locale(conn)

        conn
        |> redirect(to: ~p"/#{locale}/onboarding/region")
        |> halt()
    end
  end

  @doc """
  Redirects to home if user has already completed onboarding.
  Used for onboarding pages themselves.
  """
  def redirect_if_onboarding_completed(conn, _opts) do
    user = conn.assigns[:current_user]

    if user && Accounts.onboarding_completed?(user) do
      locale = get_locale(conn)

      conn
      |> redirect(to: signed_in_path(conn, locale))
      |> halt()
    else
      conn
    end
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  # Get locale from assigns or path params, fallback to detection/default
  defp get_locale(conn) do
    conn.assigns[:locale] ||
      conn.params["locale"] ||
      Locale.detect_locale_from_ip(conn)
  end

  defp signed_in_path(_conn, locale), do: ~p"/#{locale}/"
end
