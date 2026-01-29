defmodule AnimetanaWeb.OnboardingController do
  use AnimetanaWeb, :controller

  alias Animetana.Accounts

  @doc """
  Shows the region selection page.
  """
  def region(conn, _params) do
    user = conn.assigns.current_user
    changeset = Accounts.change_user_onboarding(user)
    render(conn, :region, changeset: changeset)
  end

  @doc """
  Handles region selection form submission.
  """
  def complete_region(conn, %{"user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.complete_onboarding(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Welcome to Animetana!")
        |> redirect(to: ~p"/")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :region, changeset: changeset)
    end
  end
end
