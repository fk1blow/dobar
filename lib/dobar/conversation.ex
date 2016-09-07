defmodule Dobar.Conversation do
  defmacro __using__(_opts) do
    quote do
      use Dobar.Conversation.Definition
      use GenServer

      @input_events_manager Dobar.InterfaceEvents
      @dialog_events_manager Dobar.DialogEvents

      def start_link do
        GenServer.start_link __MODULE__, [], name: __MODULE__
      end

      def init(_args) do
        start_children(intention_definitions)
        start_event_handlers()
        {:ok, nil}
      end

      def handle_info({:gen_event_EXIT, _handler, _reason}, state) do
        start_event_handlers()
        {:ok, state}
      end

      # Private

      defp start_children(definitions) do
        import Supervisor.Spec
        children = [
          worker(Dobar.Conversation.Intention.Provider, [[definitions: definitions]])
        ]
        Supervisor.start_link(children, strategy: :one_for_one)
      end

      defp start_event_handlers do
        GenEvent.add_mon_handler(@input_events_manager, Dobar.Conversation.TextInputHandler, nil)
        GenEvent.add_mon_handler(@dialog_events_manager, Dobar.Conversation.ReactionHandler, nil)
      end
    end
  end
end
