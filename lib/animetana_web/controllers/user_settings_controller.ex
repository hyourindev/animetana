defmodule AnimetanaWeb.UserSettingsController do
  use AnimetanaWeb, :controller

  alias Animetana.Accounts

  plug :assign_changesets

  def edit(conn, _params) do
    render(conn, :edit)
  end

  def update_profile(conn, %{"user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user_profile(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, gettext("Profile updated successfully."))
        |> redirect(to: ~p"/#{conn.assigns.locale}/settings")

      {:error, changeset} ->
        render(conn, :edit,
          profile_changeset: changeset,
          tab: "profile"
        )
    end
  end

  def update_preferences(conn, %{"user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user_preferences(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, gettext("Preferences updated successfully."))
        |> redirect(to: ~p"/#{conn.assigns.locale}/settings?tab=preferences")

      {:error, changeset} ->
        render(conn, :edit,
          preferences_changeset: changeset,
          tab: "preferences"
        )
    end
  end

  def update_privacy(conn, %{"user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user_privacy(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, gettext("Privacy settings updated successfully."))
        |> redirect(to: ~p"/#{conn.assigns.locale}/settings?tab=privacy")

      {:error, changeset} ->
        render(conn, :edit,
          privacy_changeset: changeset,
          tab: "privacy"
        )
    end
  end

  def update_email(conn, %{"user" => user_params}) do
    user = conn.assigns.current_user
    current_password = user_params["current_password"]

    changeset =
      user
      |> Accounts.change_user_email(user_params)
      |> Accounts.User.validate_current_password(current_password)

    if changeset.valid? do
      Accounts.deliver_user_update_email_instructions(
        user,
        user.email,
        &url(~p"/#{conn.assigns.locale}/users/confirm/#{&1}")
      )

      conn
      |> put_flash(:info, gettext("A link to confirm your email change has been sent to the new address."))
      |> redirect(to: ~p"/#{conn.assigns.locale}/settings?tab=account")
    else
      render(conn, :edit,
        email_changeset: changeset,
        tab: "account"
      )
    end
  end

  def update_password(conn, %{"user" => user_params}) do
    user = conn.assigns.current_user
    current_password = user_params["current_password"]

    case Accounts.update_user_password(user, current_password, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, gettext("Password updated successfully."))
        |> redirect(to: ~p"/#{conn.assigns.locale}/settings?tab=account")

      {:error, changeset} ->
        render(conn, :edit,
          password_changeset: changeset,
          tab: "account"
        )
    end
  end

  defp assign_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:profile_changeset, Accounts.change_user_profile(user))
    |> assign(:preferences_changeset, Accounts.change_user_preferences(user))
    |> assign(:privacy_changeset, Accounts.change_user_privacy(user))
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
    |> assign(:tab, conn.params["tab"] || "profile")
  end
end
