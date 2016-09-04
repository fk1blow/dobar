defmodule Dobar.Conversation.Intention do
  use GenServer

  alias Dobar.Conversation.Intention.Evaluator

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def evaluate_intent(:text, message) do
    GenServer.call __MODULE__, {:evaluate_text, message}
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:evaluate_text, message}, _from, state) do
    IO.puts "will evaluate text: #{inspect message}"
    e = Evaluator.evaluate_input({:text, message})
    {:reply, "okkkkk", state}
  end
end
