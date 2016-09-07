defmodule Dobar do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the interface events manager used by interface and Conversation api
      # worker(Dobar.GenericEventManager, [[name: :interface_events]])
      worker(GenEvent, [[name: Dobar.InterfaceEvents]], id: :interface_events),

      # Start the dialog events manager used by the dialog and conversation api
      # worker(Dobar.GenericEventManager, [[name: :dialog_events]])
      worker(GenEvent, [[name: Dobar.DialogEvents]], id: :dialog_events),

      # TEMPORARELY DISABLED FOR TESTING PURPOSE ONLY
      # Start the interface of the dialog system
      worker(Dobar.Interface, [[
        event_manager: Dobar.InterfaceEvents,
        interface_conf: Dobar.Conversation
      ]]),

      # TESTING PURPOSE ONLY
      # this is supposed to be declared by the user that wants to use Dobar
      worker(Dobar.Xapp.Definition, [])
    ]

    opts = [strategy: :one_for_one, name: Dobar.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
