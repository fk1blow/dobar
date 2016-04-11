defmodule Dobar.Conversation.Manager do
  use GenServer

  alias Dobar.Conversation.Model.Conversation
  alias Dobar.Model.Intent
  alias Dobar.Conversation.Intention.Provider, as: IntentionProvider

  @name __MODULE__

  def start_link do
    GenServer.start_link @name, [], name: @name
  end

  def init(_) do
    {:ok, %Conversation{}}
  end

  #
  # interface

  def evaluate_intention(intent) do
    GenServer.call @name, {:evaluate, intent}
  end

  #
  # callbacks

  def handle_call({:evaluate, intent}, _from, %Conversation{} = conversation) do
    conversation = process_capability(intent, conversation)
    {:reply, nil, conversation}
  end

  # private
  #

  defp process_capability(intent, %Conversation{expected: %{capability: nil}}) do
    IO.puts "expected capability is nil - start a new conversation"
    String.to_atom(intent.name)
    |> IntentionProvider.intention
    |> apply(:process_next, [intent])
    |> next_capability(intent)
  end

  defp process_capability(intent, %Conversation{expected: expected} = conversation) do
    IO.puts "expected exists - continue dialog"

    intention = String.to_atom(expected.intention) |> IntentionProvider.intention
    processed = intention |> apply(:process_expected,
      [expected.capability, conversation.intent, intent])

    case processed do
      {:continue, intent} ->
        apply(intention, :process_next, [intent]) |> next_capability(intent)
      {:halt, reason} ->
        IO.puts "### halting because: #{reason}"
        conversation
      {:error, reason} ->
        raise reason
    end
  end

  defp next_capability(next, intent) do
    case next do
      {:next, reply, capability} ->
        IO.puts "### reply from #{capability.name} is: #{reply}"
        %Conversation{expected: %{capability: capability, intention: intent.name},
                      intent: intent}
      {:ended, reply} ->
        IO.puts "fuuuuuuck, this is it: #{reply}"
        %Conversation{}
      {:error, reason} ->
        raise reason
    end
  end
end
