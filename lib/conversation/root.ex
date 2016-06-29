defmodule Dobar.Conversation.Root do
  use GenServer

  import Dobar.Conversation.Slot

  alias Dobar.Model.Intent
  alias Dobar.Model.Dialog
  alias Dobar.Conversation.Intention.Provider
  alias Dobar.Conversation.Topic

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    {:ok, nil}
  end

  def evaluate_intent(%Intent{} = intent) do
    GenServer.cast(__MODULE__, {:evaluate_intent, intent})
  end

  def handle_cast({:evaluate_intent, intent}, nil) do
    IO.puts "start of the dialog"

    dialog = %Dialog{slots: from_intent(intent)}

    intent_name = String.to_atom(intent.name)
    intent_def = Provider.intention(intent_name)

    entity_slots = only_entities(intent_def[intent_name]) |> slots_by_priority
    next_slot = slots_not_filled(dialog, entity_slots) |> first_by_priority

    Topic.start_topic(next_slot) |> start_dialog

    IO.puts "dialog: #{inspect dialog}"

    {:noreply, dialog}
  end

  def handle_cast({:evaluate_intent, intent}, %Dialog{slots: slots} = dialog) do
    IO.puts "in the middle of the dialog"

    continue = Topic.end_topic(intent.entities) |> continue_dialog(intent, dialog)
    case continue do
      {:ok, dialog} ->
        {:noreply, dialog}
      {:error, reason} ->
        {:noreply, dialog}
    end

    # dialog = %Dialog{slots: Map.merge(dialog.slots, from_intent(intent))}
    # {:noreply, dialog}
  end

  defp start_dialog({:ok, entity}) do
    IO.puts "should output question for: #{inspect entity}"
  end
  defp start_dialog({:error, reason}) do
    IO.puts "error outputting question: #{inspect reason}"
  end

  defp continue_dialog({:ok, x}, intent, dialog) do
    intent_name = String.to_atom(intent.name)
    intent_def = Provider.intention(intent_name)

    entity_slots = only_entities(intent_def[intent_name]) |> slots_by_priority
    dialog = %Dialog{slots: Map.merge(dialog.slots, from_intent(intent))}
    next_slot = slots_not_filled(dialog, entity_slots) |> first_by_priority

    Topic.start_topic(next_slot) |> start_dialog

    IO.puts "next dialog: #{inspect dialog}"
    IO.puts "next_slot: #{inspect next_slot}"

    {:ok, dialog}
  end
  defp continue_dialog({:error, reason}, intent, dialog) do
    IO.puts "heeeeeeerrrrrrreeeeeeeeeee"
    {:error, "herpdepr"}
  end
end
