defmodule AnimetanaWeb.OAuthController do
  use AnimetanaWeb, :controller

  plug Ueberauth

  alias Animetana.Accounts
  alias AnimetanaWeb.Plugs.Locale

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.find_or_create_user_from_oauth(auth) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Successfully authenticated.")
        |> AnimetanaWeb.UserAuth.log_in_user(user)

      {:error, reason} ->
        locale = get_locale(conn)

        conn
        |> put_flash(:error, "Authentication failed: #{inspect(reason)}")
        |> redirect(to: ~p"/#{locale}/users/log_in")
    end
  end

  def callback(%{assigns: %{ueberauth_failure: failure}} = conn, _params) do
    message =
      failure.errors
      |> Enum.map_join(", ", & &1.message)

    locale = get_locale(conn)

    conn
    |> put_flash(:error, "Authentication failed: #{message}")
    |> redirect(to: ~p"/#{locale}/users/log_in")
  end

  defp get_locale(conn) do
    conn.assigns[:locale] || conn.params["locale"] || Locale.detect_locale_from_ip(conn)
  end
end
