defmodule Dobar.Conversation do
  use GenServer

  alias Dobar.Conversation
  alias Conversation.DialogEvents
  alias Dobar.Model.Intent

  def start_link(opts) do
    GenServer.start_link __MODULE__, opts
  end

  def react(pid, %Intent{} = intent) do
    GenServer.cast pid, {:react, intent}
  end

  def init(args) do
    {:ok, pid} = DialogEvents.start_link
    {_id, manager_pid, _, _} = DialogEvents.get_child(pid, :dialog_event_mananger)
    manager_pid |> start_event_handlers
    {:ok, %{event_manager: manager_pid, robot: args[:robot]}}
  end

  def handle_cast({:react, %Intent{} = intent}, state) do
    IO.puts "now i should react to the intent, inside the conversation"
    {:noreply, state}
  end

  def handle_info({:gen_event_EXIT, _, _}, %{event_mananger: manager} = state) do
    start_event_handlers(manager)
    {:noreply, state}
  end

  defp start_event_handlers(manager) do
    # TODO: move the loggers inside the dialog handler, to the logging handler
    GenEvent.add_mon_handler(manager, Conversation.DialogHandler, [[conversation: self]])
    GenEvent.add_mon_handler(manager, Conversation.TimelineHandler, nil)
    # GenEvent.add_mon_handler(manager, Conversation.LoggingHandler, nil)
  end

  # defmacro __using__(_opts) do
  #   quote do
  #     use Dobar.Conversation.Definition
  #     # use GenServer

  #     raise "fucking hardcoded paths to events managers ......."
  #     @input_events_manager Dobar.InterfaceEvents
  #     @dialog_events_manager Dobar.DialogEvents

  #     def start_link do
  #       GenServer.start_link __MODULE__, [], name: __MODULE__
  #     end

  #     def init(_args) do
  #       start_children(intention_definitions)
  #       start_event_handlers()
  #       {:ok, nil}
  #     end

  #     def handle_info({:gen_event_EXIT, _handler, _reason}, state) do
  #       start_event_handlers()
  #       {:noreply, state}
  #     end

  #     defp start_children(definitions) do
  #       import Supervisor.Spec
  #       children = [
  #         worker(Dobar.Conversation.Intention.Provider, [[definitions: definitions]])
  #       ]
  #       Supervisor.start_link(children, strategy: :one_for_one)
  #     end

  #     defp start_event_handlers do
  #       GenEvent.add_mon_handler(@input_events_manager, Dobar.Conversation.TextInputHandler, nil)
  #       GenEvent.add_mon_handler(@dialog_events_manager, Dobar.Conversation.ReactionHandler, nil)
  #       # GenEvent.add_mon_handler(@dialog_events_manager, Dobar.Conversation.TimelineHandler, nil)
  #     end
  #   end
  # end
end
