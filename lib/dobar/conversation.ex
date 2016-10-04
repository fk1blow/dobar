defmodule Dobar.Conversation do
  use GenServer

  alias Dobar.Intent
  alias Dobar.Reaction
  alias Dobar.Conversation
  alias Conversation.DialogEvents
  alias Dobar.Dialog.Species.Routes, as: SpeciesRoutes
  alias Dobar.Dialog.GenericDialog

  def start_link(opts) do
    GenServer.start_link __MODULE__, opts
  end

  def react(pid, %Intent{} = intent) do
    GenServer.cast pid, {:react, intent}
  end

  def init(args) do
    {:ok, pid} = DialogEvents.start_link
    {_id, manager_pid, _, _} = DialogEvents.get_child(pid, :dialog_event_mananger)
    _ = manager_pid |> start_event_handlers
    {:ok, %{event_manager: manager_pid,
            robot: args[:robot],
            definitions: args[:definitions],
            dialog: nil}}
  end

  def handle_cast({:react, %Intent{} = intent}, %{dialog: dialog} = state) do
    dialog = case dialog do
      nil ->
        dialog = SpeciesRoutes.specie intent.name
        {:ok, pid} = dialog.start_link(:root_dialog,
          [event_manager: state.event_manager, definitions: state.definitions])
        GenericDialog.evaluate(pid, intent)
        dialog
      dialog ->
        GenericDialog.evaluate(dialog, intent)
        dialog
    end
    {:noreply, Map.merge(state, %{dialog: dialog})}
  end

  def handle_info({:gen_event_EXIT, _, _}, %{event_manager: manager} = state) do
    start_event_handlers(manager)
    {:noreply, state}
  end
  def handle_info({:dialog_reaction, %Reaction{} = reaction}, state) do
    send(state.robot, {:dialog_reaction, reaction})
    {:noreply, state}
  end

  defp start_event_handlers(manager) do
    # TODO: move the loggers inside the dialog handler, to the logging handler
    GenEvent.add_mon_handler(manager, Conversation.DialogHandler, [conversation: self])
    GenEvent.add_mon_handler(manager, Conversation.TimelineHandler, nil)
    GenEvent.add_mon_handler(manager, Conversation.LoggingHandler, nil)
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
