# TODO: ro be removed because superseded by Dobar.Robot gen server
defmodule Dobar do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, []
  end

  def init do
    children = [
      # Start the Responder
      # supervisor(Dobar.Responder.Supervisor, [[interface: Dobar.Interface]]),
      # supervisor(Dobar.Responder.Supervisor, []),

      # supervisor(Dobar.Interface.Supervisor, [[]]),

      # # Start the events manager used by interface and Conversation api
      # worker(GenEvent, [[name: interface_events_ref]], id: interface_events_ref),

      # # Start events manager used by the dialog and conversation api
      # worker(GenEvent, [[name: dialog_events_ref]], id: dialog_events_ref),

      # Start the interface of the dialog system
      # TO BE REFACTORED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      # worker(Dobar.Interface, [[
      #   # event_manager: Dobar.InterfaceEvents,
      #   event_manager: interface_events_ref,
      #   # interface_conf: Dobar.Conversation
      #   interface_conf: [adapter: opts[:adapter]]
      # ]]),

      # supervisor(Dobar.Interface.Supervisor),

      # Start the conversation definition provided by the user via config
      # worker(conversation_definition, [], id: opts[:interface_ref])
    ]

    # supervise(children, :one_for_one)
  end

  # use Application

  # def start(_type, _args) do
  #   case Code.ensure_loaded?(conversation_definition) do
  #     true -> app_supervisor
  #     false -> {:error, "conversation definition module not found"}
  #   end
  # end

  # defp conversation_definition do
  #   :dobar |> Application.get_env(Dobar.Conversation) |> Keyword.get(:definition)
  # end

  # defp app_supervisor do
  #   import Supervisor.Spec, warn: false
  #   children = [
  #     # Start the interface events manager used by interface and Conversation api
  #     worker(GenEvent, [[name: Dobar.InterfaceEvents]], id: :interface_events),

  #     # Start the dialog events manager used by the dialog and conversation api
  #     worker(GenEvent, [[name: Dobar.DialogEvents]], id: :dialog_events),

  #     # Start the interface of the dialog system
  #     worker(Dobar.Interface, [[
  #       event_manager: Dobar.InterfaceEvents,
  #       interface_conf: Dobar.Conversation
  #     ]]),

  #     # Start the conversation definition provided by the user via config
  #     worker(conversation_definition, []),

  #     # Start the Responder
  #     supervisor(Dobar.Responder.Supervisor, [[interface: Dobar.Interface]]),
  #   ]

  #   opts = [strategy: :one_for_one, name: Dobar.Supervisor]
  #   Supervisor.start_link(children, opts)
  # end
end
