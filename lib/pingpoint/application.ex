defmodule Pingpoint.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PingpointWeb.Telemetry,
      Pingpoint.Repo,
      {DNSCluster, query: Application.get_env(:pingpoint, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Pingpoint.PubSub},
      PingpointWeb.Presence,
      # Start the Finch HTTP client for sending emails
      {Finch, name: Pingpoint.Finch},
      # Start a worker by calling: Pingpoint.Worker.start_link(arg)
      # {Pingpoint.Worker, arg},
      {DynamicSupervisor, name: Pingpoint.DynamicSupervisor, strategy: :one_for_one},
      # Start to serve requests, typically the last entry
      PingpointWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pingpoint.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PingpointWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
