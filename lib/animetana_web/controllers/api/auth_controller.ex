defmodule AnimetanaWeb.Api.AuthController do
  use AnimetanaWeb, :controller

  alias Animetana.Accounts
  alias Animetana.Accounts.Token

  # Default locale for email URLs sent from API
  @default_email_locale "en"

  def register(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/#{@default_email_locale}/users/confirm/#{&1}")
          )

        {:ok, access_token} = Token.generate_access_token(user)
        {:ok, refresh_token} = Token.generate_refresh_token(user)

        conn
        |> put_status(:created)
        |> json(%{
          user: user_json(user),
          access_token: access_token,
          refresh_token: refresh_token
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_changeset_errors(changeset)})
    end
  end

  def login(conn, %{"login" => login, "password" => password}) do
    case Accounts.get_user_by_email_or_identifier_and_password(login, password) do
      %Accounts.User{} = user ->
        {:ok, access_token} = Token.generate_access_token(user)
        {:ok, refresh_token} = Token.generate_refresh_token(user)

        json(conn, %{
          user: user_json(user),
          access_token: access_token,
          refresh_token: refresh_token
        })

      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid credentials"})
    end
  end

  def refresh(conn, %{"refresh_token" => refresh_token}) do
    case Token.verify_refresh_token(refresh_token) do
      {:ok, %{"user_id" => user_id}} ->
        case Accounts.get_user(user_id) do
          %Accounts.User{} = user ->
            {:ok, access_token} = Token.generate_access_token(user)
            json(conn, %{access_token: access_token})

          nil ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "User not found"})
        end

      {:error, _} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid or expired refresh token"})
    end
  end

  @doc """
  Complete onboarding by selecting region. Requires authentication.
  """
  def complete_onboarding(conn, %{"region" => region}) do
    user = conn.assigns.current_user

    if Accounts.onboarding_completed?(user) do
      conn
      |> put_status(:conflict)
      |> json(%{error: "Onboarding already completed"})
    else
      case Accounts.complete_onboarding(user, %{region: region}) do
        {:ok, updated_user} ->
          json(conn, %{user: user_json(updated_user)})

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: translate_changeset_errors(changeset)})
      end
    end
  end

  @doc """
  Get current user info. Requires authentication.
  """
  def me(conn, _params) do
    user = conn.assigns.current_user
    json(conn, %{user: user_json(user)})
  end

  defp user_json(user) do
    %{
      id: user.id,
      name: user.name,
      identifier: user.identifier,
      email: user.email,
      region: user.region,
      onboarding_completed: Accounts.onboarding_completed?(user)
    }
  end

  defp translate_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
