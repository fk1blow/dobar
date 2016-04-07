defmodule Dobar.Conversation.Manager do
  use GenServer

  alias Dobar.Conversation.Model.Conversation
  alias Dobar.Model.Intent
  alias Dobar.Conversation.Intention.Provider, as: IntentionProvider
  alias Dobar.Conversation.Intention

  @name __MODULE__

  def start_link do
    GenServer.start_link @name, [], name: @name
  end

  def init(_) do
    {:ok, %Conversation{}}
  end

  #
  # interface

  def evaluate_intention(%Intent{} = intent) do
    GenServer.call @name, {:evaluate, intent}
  end

  #
  # callbacks

  def handle_call({:evaluate, intent}, _from, %Conversation{expected: nil}) do
    IO.puts "expected is nil - should start a new conversation"

    intention = IntentionProvider.intention String.to_atom intent.name
    next = apply intention, :process_next, [intent]

    conversation = case next do
      {:next, capability} ->
        Map.put %Conversation{}, :expected, capability
      _ ->
        raise "cannot evaluate the intention"
    end

    {:reply, nil, conversation}
  end

  def handle_call({:evaluate, intent}, _from, %Conversation{} = conversation) do
    IO.puts "expected exists - proceed with the current conversation"
    {:reply, nil, conversation}
  end
end
