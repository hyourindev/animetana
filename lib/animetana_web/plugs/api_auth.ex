defmodule AnimetanaWeb.ApiAuth do
  @behaviour Plug

  import Plug.Conn
  import Phoenix.Controller

  alias Animetana.Accounts
  alias Animetana.Accounts.Token

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, claims} <- Token.verify_access_token(token),
         %Accounts.User{} = user <- Accounts.get_user(claims["user_id"]) do
      assign(conn, :current_user, user)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Authentication required"})
        |> halt()
    end
  end
end
