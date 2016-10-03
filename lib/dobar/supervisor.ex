defmodule Dobar.Supervisor do
  def start_link(opts \\ []) do
    case Code.ensure_loaded?(conversation_definition) do
      true -> dobar_supervisor(opts)
      false -> {:error, "conversation definition module not found"}
    end
  end

  defp conversation_definition do
    :dobar |> Application.get_env(Dobar.Conversation) |> Keyword.get(:definition)
  end

  defp dobar_supervisor(opts) do
    import Supervisor.Spec, warn: false

    # build the interface events and dialog events ids
    interface_ref = make_ref()
    dialog_ref = make_ref()

    children = [
      # Start the events manager used by interface and Conversation api
      worker(GenEvent, [[name: Dobar.InterfaceEvents]], id: interface_ref),

      # Start events manager used by the dialog and conversation api
      worker(GenEvent, [[name: Dobar.DialogEvents]], id: interface_ref),

      # Start the interface of the dialog system
      worker(Dobar.Interface, [[
        event_manager: Dobar.InterfaceEvents,
        # interface_conf: Dobar.Conversation
        interface_conf: Dobar.Conversation
      ]]),

      # Start the conversation definition provided by the user via config
      worker(conversation_definition, []),

      # Start the Responder
      supervisor(Dobar.Responder.Supervisor, [[interface: Dobar.Interface]]),
    ]

    opts = [strategy: :one_for_one, name: Dobar.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp managers_ids, do: {make_ref(), make_ref()}
end
