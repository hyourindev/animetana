defmodule Yunaos.Repo do
  use Ecto.Repo,
    otp_app: :yunaos,
    adapter: Ecto.Adapters.Postgres
end
