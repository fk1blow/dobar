defmodule Dobar do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the intent supervisor
      # supervisor(Dobar.Intent, []),
      # Start the dialog supervisor
      # supervisor(Dobar.Dialog, []),

      # Start the interface events manager used by both interface and Conversation api
      worker(Dobar.InterfaceEvents, []),
      # Start the interface of the dialog system
      supervisor(Dobar.Interface.Supervisor, [[event_manager: Dobar.InterfaceEvents]]),
      # Start the conversation supervisor
      supervisor(Dobar.Conversation.Supervisor, [[input_events_manager: Dobar.InterfaceEvents]])
    ]

    opts = [strategy: :one_for_one, name: Dobar.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Dobar.Endpoint.config_change(changed, removed)
    :ok
  end
end
