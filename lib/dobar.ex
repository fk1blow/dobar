defmodule Dobar do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the interface events manager used by interface and Conversation api
      worker(GenEvent, [[name: Dobar.InterfaceEvents]], id: :interface_events),

      # Start the dialog events manager used by the dialog and conversation api
      worker(GenEvent, [[name: Dobar.DialogEvents]], id: :dialog_events),

      # Start the interface of the dialog system
      worker(Dobar.Interface, [[
        event_manager: Dobar.InterfaceEvents,
        interface_conf: Dobar.Conversation
      ]]),

      # TESTING PURPOSE ONLY
      # this is supposed to be declared by the user that wants to use Dobar
      worker(Dobar.Xapp.Definition, []),

      # Start the Responder
      supervisor(Dobar.Responder.Supervisor, [[interface: Dobar.Interface]]),
    ]

    opts = [strategy: :one_for_one, name: Dobar.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
