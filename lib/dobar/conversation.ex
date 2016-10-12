defmodule Dobar.Conversation do
  use GenServer

  alias Dobar.Intent
  alias Dobar.Reaction
  alias Dobar.Conversation
  alias Dobar.Dialog.Species.Routes, as: SpeciesRoutes
  alias Dobar.Dialog.GenericDialog

  @doc """
  Start a new conversation with the given configuration keyword list.
  """
  def start_link(conf) do
    GenServer.start_link __MODULE__, conf
  end

  @doc """
  Provide an intent to the conversation.
  """
  def provide(pid, %Intent{} = intent) do
    GenServer.cast pid, {:provide_intent, intent}
  end

  def init(args) do
    start_event_handlers(:dialog_events_mananger)
    {:ok, %{robot: args[:robot],
            definitions: args[:definitions],
            dialog: nil}}
  end

  def handle_cast({:provide_intent, %Intent{} = intent}, %{dialog: dialog} = state) do
    dialog = case dialog do
      nil ->
        create_and_evaluate_dialog(intent, :dialog_events_mananger, state.definitions)
      dialog ->
        if Process.alive?(dialog) do
          GenericDialog.evaluate(dialog, intent)
          dialog
        else
          create_and_evaluate_dialog(intent, :dialog_events_mananger, state.definitions)
        end
    end
    {:noreply, Map.merge(state, %{dialog: dialog})}
  end

  def handle_info({:EXIT, pid, :normal}, %{dialog: dialog} = state) do
    # this should never happen, actually
    state = if dialog === pid,
      do: Map.merge(state, %{dialog: nil}),
    else: state
    {:noreply, state}
  end
  def handle_info({:gen_event_EXIT, _, _}, state) do
    start_event_handlers(:dialog_events_mananger)
    {:noreply, state}
  end
  def handle_info({:dialog_reaction, %Reaction{} = reaction}, state) do
    send(state.robot, {:dialog_reaction, reaction})
    {:noreply, state}
  end
  def handle_info({:switch_dialog, %Reaction{trigger: %Intent{} = intent}}, state) do
    dialog = create_and_evaluate_dialog(intent, :dialog_events_mananger, state.definitions)
    {:noreply, Map.merge(state, %{dialog: dialog})}
  end

  defp start_event_handlers(manager) do
    GenEvent.add_mon_handler(manager, Conversation.DialogHandler, [conversation: self])
    GenEvent.add_mon_handler(manager, Conversation.LoggingHandler, nil)
  end

  defp create_and_evaluate_dialog(%Intent{name: name} = intent, event_manager, definitions) do
    dialog = SpeciesRoutes.specie(name)
    Process.flag(:trap_exit, true)
    {:ok, dialog_pid} = dialog.start_link(:root_dialog,
      [event_manager: event_manager, definitions: definitions])
    GenericDialog.evaluate(dialog_pid, intent)
    dialog_pid
  end
end
