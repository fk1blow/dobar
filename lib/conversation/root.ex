defmodule Dobar.Conversation.Root do
  use GenServer

  alias Dobar.Conversation.Slot

  alias Dobar.Model.Intent
  alias Dobar.Model.Dialog
  alias Dobar.Conversation.Topic

  def start_link(name) do
    GenServer.start_link __MODULE__, nil, name: name
  end

  def init(initial_state) do
    {:ok, initial_state}
  end

  def evaluate_intent(pid, %Intent{} = intent) do
    GenServer.cast(pid, {:evaluate_intent, intent})
  end

  #
  # genserver Callbacks

  def handle_cast({:evaluate_intent, intent}, nil) do
    IO.puts "begin dialog for intent: #{inspect intent}"

    {:ok, dialog} = Dobar.Conversation.Dialog.start_link(:main_dialog, intent)
    xreact = Dobar.Conversation.Dialog.next_topic(dialog)
    IO.puts "xreact: #{inspect xreact}"


    # dialog = %Dialog{slots: Slot.from_intent(intent), intent_name: intent.name}
    # next_slot = Slot.next_from_dialog intent, dialog

    # Topic.start_topic(next_slot) |> output_dialog(dialog)

    # with {:ok, slot} <- Slot.next_from_dialog(intent, dialog),
    #      {:ok, topic} <- Topic.start_topic(slot) do
    #   IO.puts "should start the topic: #{inspect topic}"
    # else
    #   {:error, reason} ->
    #     IO.puts "error: cannot start because: #{inspect reason}"
    # end

    # {:noreply, {dialog, next_slot}}
    {:noreply, dialog}
  end
  def handle_cast({:evaluate_intent, intent}, dialog) do
    IO.puts "continue dialog: #{inspect dialog}, intent: #{inspect intent}"

    xreact = Dobar.Conversation.Dialog.react(dialog, intent)
    IO.puts "xreact: #{inspect xreact}"

    # dialog = %{dialog | slots: Map.merge(dialog.slots, Slot.from_intent(intent))}
    # next_slot = Slot.next_from_dialog intent, dialog

    # with {:ok, entities, slot_key} <- Topic.end_topic(intent, slot),


    {:noreply, dialog}
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
    # Topic.start_topic(next_slot) |> output_dialog(dialog)
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
