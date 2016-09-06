defmodule Dobar.Conversation do
  use GenServer

  @server __MODULE__

  def start_link(opts) do
    GenServer.start_link @server, opts, name: @server
  end

  def init(args) do
    event_handlers = %{input_events_manager: args[:input_events_manager],
              dialog_events_manager: args[:dialog_events_manager]}
    start_event_handlers(event_handlers)
    {:ok, event_handlers}
  end

  def handle_info({:gen_event_EXIT, _handler, _reason}, state) do
    start_event_handlers(state)
    {:ok, state}
  end

  defp start_event_handlers(event_managers) do
    GenEvent.add_mon_handler(
      event_managers[:input_events_manager], Dobar.Conversation.TextInputHandler, nil)

    GenEvent.add_mon_handler(
      event_managers[:dialog_events_manager], Dobar.Conversation.ReactionHandler, nil)
  end
end
