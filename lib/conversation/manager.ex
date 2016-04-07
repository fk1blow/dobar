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

  def handle_call({:evaluate, intent}, _from, %Conversation{} = conversation) do
    conversation = process_expected(intent, conversation)
    {:reply, nil, conversation}
  end

  # private
  #

  defp process_expected(intent, %Conversation{expected: %{capability: nil}}) do
    IO.puts "expected capability is nil - start a new conversation"

    intention = IntentionProvider.intention String.to_atom intent.name
    next = apply intention, :process_next, [intent]

    conversation = case next do
      {:next, reply, capability} ->
        IO.puts "### reply from #{capability.name} is: #{reply}"
        %Conversation{expected: %{capability: capability, intention: intent.name},
                      intent: intent}
      _ ->
        raise "cannot evaluate the intention"
    end
  end

  defp process_expected(intent, %Conversation{} = conversation) do
    IO.puts "expected exists - continue dialog"

    intention = IntentionProvider.intention String.to_atom conversation.expected.intention
    expected = apply intention, :process_expected,
      [conversation.expected.capability, conversation.intent, intent]

    IO.puts "### evaluated expected is: #{inspect expected}"
  end
end
