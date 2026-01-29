defmodule Animetana.Repo do
  use Ecto.Repo,
    otp_app: :animetana,
    adapter: Ecto.Adapters.Postgres
end
