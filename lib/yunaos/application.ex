defmodule Yunaos.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      YunaosWeb.Telemetry,
      Yunaos.Repo,
      {DNSCluster, query: Application.get_env(:yunaos, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Yunaos.PubSub},
      # Start a worker by calling: Yunaos.Worker.start_link(arg)
      # {Yunaos.Worker, arg},
      # Start to serve requests, typically the last entry
      YunaosWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Yunaos.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    YunaosWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
