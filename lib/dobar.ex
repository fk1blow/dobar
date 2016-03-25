defmodule Dobar do
  use Application

  alias Dobar.Intent.IntentHandler

  @intent_event_manager Dobar.Intent.EventManager

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the endpoint when the application starts
      supervisor(Dobar.Endpoint, []),
      # Start the Ecto repository
      supervisor(Dobar.Repo, []),
      # Here you could define other workers and supervisors as children
      # worker(Dobar.Worker, [arg1, arg2, arg3]),
      supervisor(Dobar.Kapyz, []),
      # intent events manager
      worker(GenEvent, [[name: @intent_event_manager]])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dobar.Supervisor]
    # Supervisor.start_link(children, opts)

    with {:ok, pid} <- Supervisor.start_link(children, opts),
      :ok <- IntentHandler.register_with_manager(@intent_event_manager),
      do: {:ok, pid}
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Dobar.Endpoint.config_change(changed, removed)
    :ok
  end
end
