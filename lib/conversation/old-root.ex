defmodule Dobar.Conversation.OldRoot do
  use GenServer

  alias Dobar.Conversation.Slot

  alias Dobar.Model.Intent
  alias Dobar.Model.Dialog
  alias Dobar.Conversation.Topic

  def start_link(name) do
    GenServer.start_link __MODULE__, nil, name: name
  end

  def init(initial) do
    {:ok, initial}
  end

  def evaluate_intent(pid, %Intent{} = intent) do
    GenServer.cast(pid, {:evaluate_intent, intent})
  end

  #
  # genserver Callbacks

  def handle_cast({:evaluate_intent, intent}, nil) do
    IO.puts "begin dialog for intent: #{inspect intent}"
    dialog = %Dialog{slots: Slot.from_intent(intent), intent_name: intent.name}
    next_slot = Slot.next_from_dialog intent, dialog
    Topic.start_topic(next_slot) |> output_dialog(dialog)
    {:noreply, {dialog, next_slot}}
  end
  def handle_cast({:evaluate_intent, intent}, {%Dialog{meta: nil} = dialog, slot}) do
    IO.puts "continue dialog: #{inspect dialog}, intent: #{inspect intent}"

    topic_answer = Topic.end_topic(intent, slot)

    case continue_dialog(topic_answer, intent, dialog) do
      {:ok, dialog, next_slot} ->
        {:noreply, {dialog, next_slot}}
      {:meta, intent} ->
        {:ok, pid} = Dobar.Conversation.Root.start_link :root_meta_cancel
        Dobar.Conversation.Root.evaluate_intent pid, intent
        {:noreply, {%{dialog | meta: pid}, slot}}
      {:error, _reason} ->
        {:noreply, {dialog, slot}}
    end
  end
  def handle_cast({:evaluate_intent, intent}, {%Dialog{meta: pid} = dialog, slot}) do
    IO.puts "ohooooooooooooo xoxoxoxoxoxoxo"
    Dobar.Conversation.Root.evaluate_intent pid, intent
    {:noreply, dialog}
  end

  #
  # Private functions

  defp output_dialog({:ok, entity}, _dialog) do
    IO.puts "should output question for: #{inspect entity}"
  end
  defp output_dialog({:ended, _reason}, %Dialog{} = dialog) do
    IO.puts "dialog ended: #{inspect dialog}"
  end

  defp continue_dialog({:ok, _entities, _last_slot}, intent, dialog) do
    dialog = %{dialog | slots: Map.merge(dialog.slots, Slot.from_intent(intent))}
    next_slot = Slot.next_from_dialog intent, dialog
    Topic.start_topic(next_slot) |> output_dialog(dialog)
    {:ok, dialog, next_slot}
  end
  defp continue_dialog({:error, _entities, last_slot}, intent, dialog) do
    IO.puts "cannot continue because because no matched slot: #{inspect last_slot}"
    cancel_dialog?(intent) |> meta_dialog(intent)
    # {:error, "herpdepr"}
  end

  defp cancel_dialog?(%Intent{name: name}) do
    case name do
      "cancel_command" -> true
      _ -> false
    end
  end

  defp meta_dialog(true, intent) do
    IO.puts "should start new meta"
    {:meta, intent}
  end
  defp meta_dialog(false, _) do
    IO.puts "fuuuuuck you, do not want"
    {:error, "herpderrp"}
  end
end
