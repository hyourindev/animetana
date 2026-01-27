defmodule YunaosWeb.UserSessionController do
  use YunaosWeb, :controller

  alias Yunaos.Accounts
  alias YunaosWeb.UserAuth

  def new(conn, _params) do
    render(conn, :new, error_message: nil)
  end

  def create(conn, %{"user" => %{"login" => login, "password" => password} = user_params}) do
    if user = Accounts.get_user_by_email_or_identifier_and_password(login, password) do
      conn
      |> put_flash(:info, "Welcome back!")
      |> UserAuth.log_in_user(user, user_params)
    else
      render(conn, :new, error_message: "Invalid email/username or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
