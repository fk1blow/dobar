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
    {ok, manager} = GenEvent.start_link
    manager |> start_event_handlers
    {:ok, %{
      robot: args[:robot],
      definitions: args[:definitions],
      dialog: nil,
      event_manager: manager}}
  end

  def handle_cast({:provide_intent, %Intent{} = intent}, %{dialog: dialog} = state) do
    dialog = case dialog do
      nil ->
        {:ok, dialog} = create_dialog(intent, state.event_manager, state.definitions)
        GenericDialog.evaluate(dialog, intent)
        dialog
      dialog ->
        if Process.alive?(dialog) do
          GenericDialog.evaluate(dialog, intent)
          dialog
        else
          {:ok, dialog} = create_dialog(intent, state.event_manager, state.definitions)
          GenericDialog.evaluate(dialog, intent)
          dialog
        end
    end
    {:noreply, Map.merge(state, %{dialog: dialog})}
  end

  def handle_info({:gen_event_EXIT, _, _}, state) do
    start_event_handlers(state.event_manager)
    {:noreply, state}
  end
  def handle_info({:dialog_reaction, %Reaction{} = reaction}, state) do
    send(state.robot, {:dialog_reaction, reaction})
    {:noreply, state}
  end
  def handle_info({:switch_dialog, %Reaction{trigger: %Intent{} = intent}}, state) do
    {:ok, dialog} = create_dialog(intent, state.event_manager, state.definitions)
    GenericDialog.evaluate(dialog, intent)
    {:noreply, Map.merge(state, %{dialog: dialog})}
  end

  defp start_event_handlers(manager) do
    GenEvent.add_mon_handler(manager, Conversation.DialogHandler, [conversation: self])
    GenEvent.add_mon_handler(manager, Conversation.LoggingHandler, nil)
  end

  defp create_dialog(%Intent{name: name}, event_manager, definitions) do
    dialog_specie = SpeciesRoutes.specie(name)
    dialog_specie.start_link :root_dialog, [
      event_manager: event_manager,
      definitions: definitions]
  end
end
