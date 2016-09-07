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
      supervisor(Dobar.Interface.Supervisor, [[
        event_manager: Dobar.InterfaceEvents,
        interface_conf: Dobar.Conversation]]),

      # Moving to the second stage where the Conversation module has different
      # responsabilities and therefore completely different thant this one
      # Start the conversation supervisor
      # supervisor(Dobar.Conversation.Supervisor, [[
      #   input_events_manager: Dobar.InterfaceEvents,
      #   dialog_events_manager: Dobar.DialogEvents]])

      # TESTING PURPOSE ONLY
      worker(Dobar.Xapp.Conversation.Definition, [[
        input_events_manager: Dobar.InterfaceEvents,
        dialog_events_manager: Dobar.DialogEvents
      ]])
    ]

    opts = [strategy: :one_for_one, name: Dobar.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
