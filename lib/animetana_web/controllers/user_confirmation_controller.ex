defmodule AnimetanaWeb.UserConfirmationController do
  use AnimetanaWeb, :controller

  alias Animetana.Accounts

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    locale = conn.assigns[:locale] || "en"

    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/#{locale}/users/confirm/#{&1}")
      )
    end

    conn
    |> put_flash(:info, "If your email is in our system and unconfirmed, you will receive an email shortly.")
    |> redirect(to: ~p"/")
  end

  def edit(conn, %{"token" => token}) do
    render(conn, :edit, token: token)
  end

  def update(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Account confirmed successfully.")
        |> redirect(to: ~p"/")

      :error ->
        conn
        |> put_flash(:error, "Confirmation link is invalid or has expired.")
        |> redirect(to: ~p"/")
    end
  end
end
