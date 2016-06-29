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

    {:ok, dialog} = begin_dialog(intent)

    {:noreply, dialog}
  end

  def handle_cast({:evaluate_intent, intent}, %Dialog{slots: slots} = dialog) do
    IO.puts "in the middle of the dialog"

    topic_answer = Topic.end_topic(intent.entities)

    case continue_dialog(topic_answer, intent, dialog) do
      {:ok, dialog} ->
        {:noreply, dialog}
      {:error, reason} ->
        {:noreply, dialog}
    end
  end

  defp output_dialog({:ok, entity}, %Dialog{} = dialog) do
    IO.puts "should output question for: #{inspect entity}"
  end
  defp output_dialog({:ended, reason}, %Dialog{} = dialog) do
    IO.puts "dialog ended: #{inspect dialog}"
  end

  defp begin_dialog(intent) do
    dialog = %Dialog{slots: from_intent(intent)}
    next_slot = next_from_dialog intent, dialog
    Topic.start_topic(next_slot) |> output_dialog(dialog)
    {:ok, dialog}
  end

  defp continue_dialog({:ok, _}, intent, dialog) do
    dialog = %Dialog{slots: Map.merge(dialog.slots, from_intent(intent))}
    next_slot = next_from_dialog intent, dialog
    Topic.start_topic(next_slot) |> output_dialog(dialog)
    {:ok, dialog}
  end
  defp continue_dialog({:error, reason}, intent, dialog) do
    IO.puts "heeeeeeerrrrrrreeeeeeeeeee"
    {:error, "herpdepr"}
  end
end
