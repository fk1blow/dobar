defmodule Dobar.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Dobar.Repo,
      # Start the Telemetry supervisor
      DobarWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Dobar.PubSub},
      # Start the Endpoint (http/https)
      DobarWeb.Endpoint,
      # this is the Flow scheduler
      %{
        id: Dobar.Flow.Scheduler,
        start: {Dobar.Flow.Scheduler, :start_link, [[name: Flow.Scheduler]]}
      },
      Dobar.Flow.Scheduler.SchedulerSupervisor,
      # Scheduler's Registry
      {Registry, keys: :unique, name: Dobar.Flow.Scheduler.Registry}
      # Start a worker by calling: Dobar.Worker.start_link(arg)
      # {Dobar.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dobar.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DobarWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
