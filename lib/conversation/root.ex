defmodule Dobar.Conversation.Root do
  use GenServer

  alias Dobar.Model.Intent

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
    IO.puts "begin dialog"

    {:ok, dialog} = Dobar.Conversation.Dialog.start_link(:main_dialog, intent)

    case Dobar.Conversation.Dialog.next_topic(dialog) do
      {:topic, question}   ->
        IO.puts "Topic: question #{inspect question}"
      {:completed, topics} ->
        IO.puts "The dialog has been completed; topics: #{inspect topics}"
    end

    {:noreply, dialog}
  end

  def handle_cast({:evaluate_intent, intent}, dialog) do
    IO.puts "continue dialog"

    dialog = case Dobar.Conversation.Dialog.react(dialog, intent) do
      {:topic, question} ->
        IO.puts "Topic: question #{inspect question}"
        dialog
      {:completed, topics} ->
        IO.puts "The dialog has been completed; topics: #{inspect topics}"
        nil
      {:nomatch, reason} ->
        IO.puts "cannot match: #{inspect reason}"
        dialog
    end

    {:noreply, dialog}
  end
end
