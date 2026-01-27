defmodule YunaosWeb.OAuthController do
  use YunaosWeb, :controller

  plug Ueberauth

  alias Yunaos.Accounts

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.find_or_create_user_from_oauth(auth) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Successfully authenticated.")
        |> YunaosWeb.UserAuth.log_in_user(user)

      {:error, reason} ->
        conn
        |> put_flash(:error, "Authentication failed: #{inspect(reason)}")
        |> redirect(to: ~p"/users/log_in")
    end
  end

  def callback(%{assigns: %{ueberauth_failure: failure}} = conn, _params) do
    message =
      failure.errors
      |> Enum.map_join(", ", & &1.message)

    conn
    |> put_flash(:error, "Authentication failed: #{message}")
    |> redirect(to: ~p"/users/log_in")
  end
end
