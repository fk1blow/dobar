defmodule Dobar.Conversation do
  use GenServer

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    start_dialog_handlers
    {:ok, nil}
  end

  def handle_info({:gen_event_EXIT, _handler, _reason}, manager) do
    start_dialog_handlers
    {:ok, nil}
  end

  defp start_dialog_handler do
    GenEvent.add_mon_handler(:dialog_events, Dobar.Dialog.ReactionsHandler, nil)
    GenEvent.add_mon_handler(:dialog_events, Dobar.Dialog.InputHandler, nil)
  end
end
