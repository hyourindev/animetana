defmodule Animetana.Accounts.Token do
  use Joken.Config

  @access_token_ttl 15 * 60
  @refresh_token_ttl 30 * 24 * 60 * 60

  @impl true
  def token_config do
    default_claims(skip: [:aud, :iat, :iss, :jti, :nbf])
  end

  def generate_access_token(user) do
    extra_claims = %{
      "user_id" => user.id,
      "type" => "access",
      "exp" => Joken.current_time() + @access_token_ttl
    }

    generate_and_sign(extra_claims, signer())
  end

  def generate_refresh_token(user) do
    extra_claims = %{
      "user_id" => user.id,
      "type" => "refresh",
      "exp" => Joken.current_time() + @refresh_token_ttl
    }

    generate_and_sign(extra_claims, signer())
  end

  def verify_access_token(token) do
    with {:ok, claims} <- verify_and_validate(token, signer()),
         "access" <- Map.get(claims, "type") do
      {:ok, claims}
    else
      _ -> {:error, :invalid_token}
    end
  end

  def verify_refresh_token(token) do
    with {:ok, claims} <- verify_and_validate(token, signer()),
         "refresh" <- Map.get(claims, "type") do
      {:ok, claims}
    else
      _ -> {:error, :invalid_token}
    end
  end

  defp signer do
    secret = Application.fetch_env!(:animetana, :jwt_secret)
    Joken.Signer.create("HS256", secret)
  end
end
