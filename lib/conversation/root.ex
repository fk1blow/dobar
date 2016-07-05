defmodule Dobar.Conversation.Root do
  use GenServer

  alias Dobar.Conversation.Slot

  alias Dobar.Model.Intent
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

    {:noreply, dialog}
  end

  def handle_cast({:evaluate_intent, intent}, dialog) do
    IO.puts "continue dialog: #{inspect dialog}, intent: #{inspect intent}"

    xreact = Dobar.Conversation.Dialog.react(dialog, intent)
    IO.puts "xreact b: #{inspect xreact}"

    {:noreply, dialog}
  end

  #
  # Private functions

  defp cancel_dialog?(%Intent{name: name}) do
    case name do
      "cancel_command" -> true
      _ -> false
    end
  end
end
