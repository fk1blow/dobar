defmodule Dobar.Conversation.Manager do
  use GenServer

  alias Dobar.Conversation.Model.Conversation
  alias Dobar.Model.Intent
  alias Dobar.Conversation.Intention.Provider, as: IntentionProvider
  alias Dobar.Conversation.ConversationHandler

  @name __MODULE__

  def start_link do
    GenServer.start_link @name, [], name: @name
  end

  def init(_) do
    GenEvent.add_handler :intention_events, ConversationHandler, nil
    {:ok, %Conversation{}}
  end

  #
  # interface

  def evaluate_intention(intent) do
    GenServer.cast @name, {:evaluate, intent}
  end

  #
  # callbacks

  def handle_cast({:evaluate, intent}, conversation) do
    conversation = started(conversation)
    |> validate_confidence(intent)
    |> evaluate_intent(conversation)
    {:noreply, conversation}
  end

  # private
  #

  defp started(%Conversation{expected: %{topic: nil}} = conversation) do
    {:not_started, conversation}
  end
  defp started(conversation), do: {:started, conversation}

  defp validate_confidence({:started, _}, intent), do: {:confident, intent}
  defp validate_confidence({:not_started, _}, intent) do
    case intent do
      %Intent{confidence: confidence} when confidence >= 0.5 ->
        {:confident, intent}
      _ ->
        {:unconfident, intent}
    end
  end

  defp evaluate_intent({:confident, intent}, conversation) do
    expected_topic intent, conversation
  end
  defp evaluate_intent({:unconfident, intent}, _conversation) do
    GenEvent.notify :intention_events, {:intention_unconfident, intent}
    %Conversation{}
  end

  defp expected_topic(intent, %Conversation{expected: %{topic: nil}}) do
    GenEvent.notify :intention_events, {:conversation_start, intent}
    String.to_atom(intent.name)
    |> IntentionProvider.intention
    |> apply(:process_next, [intent])
    |> next_topic(intent)
  end
  defp expected_topic(intent, %Conversation{expected: expected} = conversation) do
    intention = String.to_atom(expected.intention) |> IntentionProvider.intention
    processed = intention |> apply(:process_expected,
      [expected.topic, conversation.intent, intent])

    case processed do
      {:continue, intent} ->
        apply(intention, :process_next, [intent]) |> next_topic(intent)
      {:halt, reason} ->
        GenEvent.notify :intention_events, {:conversation_halt, reason}
        conversation
    end
  end

  defp next_topic(next, intent) do
    case next do
      {:next, reply, topic} ->
        GenEvent.notify :intention_events, {:conversation_reply, reply}
        %Conversation{expected: %{topic: topic, intention: intent.name},
                      intent: intent}
      {:ended, reply, intent} ->
        GenEvent.notify :intention_events, {:conversation_end, reply, intent}
        %Conversation{}
      {:error, reason} ->
        GenEvent.notify :intention_events, {:conversation_error, reason}
        %Conversation{}
    end
  end
end
