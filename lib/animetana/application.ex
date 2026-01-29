defmodule Animetana.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AnimetanaWeb.Telemetry,
      Animetana.Repo,
      {DNSCluster, query: Application.get_env(:animetana, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Animetana.PubSub},
      # Start to serve requests, typically the last entry
      AnimetanaWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Animetana.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AnimetanaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
