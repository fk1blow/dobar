defmodule Dobar.Conversation do
  defmacro __using__(_opts) do
    quote do
      use Dobar.Conversation.Definition
      use GenServer

      def start_link(opts) do
        GenServer.start_link __MODULE__, opts, name: __MODULE__
      end

      def init(args) do
        _ = start_children
        event_handlers = %{input_events_manager: args[:input_events_manager],
                           dialog_events_manager: args[:dialog_events_manager]}
        start_event_handlers(event_handlers)
        {:ok, event_handlers}
      end

      def handle_info({:gen_event_EXIT, _handler, _reason}, state) do
        start_event_handlers(state)
        {:ok, state}
      end

      # Private

      defp start_children do
        import Supervisor.Spec
        children = [
          worker(Dobar.Conversation.Intention.Provider, [[definitions: intentions]])
        ]
        Supervisor.start_link(children, strategy: :one_for_one)
      end

      defp start_event_handlers(event_managers) do
          GenEvent.add_mon_handler(
            event_managers[:input_events_manager], Dobar.Conversation.TextInputHandler, nil)

          GenEvent.add_mon_handler(
            event_managers[:dialog_events_manager], Dobar.Conversation.ReactionHandler, nil)
      end
    end
  end
end
