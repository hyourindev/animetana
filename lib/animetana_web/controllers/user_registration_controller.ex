defmodule AnimetanaWeb.UserRegistrationController do
  use AnimetanaWeb, :controller

  alias Animetana.Accounts
  alias Animetana.Accounts.User

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    locale = conn.assigns[:locale] || "en"

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/#{locale}/users/confirm/#{&1}")
          )

        conn
        |> put_flash(:info, "Account created successfully. Please check your email to confirm.")
        |> AnimetanaWeb.UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end
