defmodule Dobar.Conversation.Intention.Evaluator do
  @moduledoc """
  It extracts the intent from an input(text, for now) and outputs an
  %Intent struct the intent representation

  To evaluate the input, it needs a service that knows how to evaluate
  such types of input, services like wit.ai - default, for now
  """

  alias Dobar.Model.Intent

  @default_evaluator Dobar.Conversation.Intention.Evaluator.Wit

  def evaluate_input({:text, input}) do
    call_intention_api(input)
    |> parse_intention
    |> notify_handlers
  end

  defp parse_intention({:error, error}), do: {:error, error}
  defp parse_intention({:ok, intention}) do
    intent = hd intention.outcomes
    {:ok, %Intent{name: intent.intent, input: intent._text,
      entities: intent.entities, confidence: intent.confidence}}
  end

  defp notify_handlers({:error, error}) do
    # GenEvent.notify(:intent_events, {:intention_evaluation_error, error})
  end
  defp notify_handlers({:ok, intent}) do
    IO.puts "evaluated intent: #{inspect intent}"
    IO.puts "should pass the intent back to the conversation... somehow"
    # GenEvent.notify(:intent_events, {:intention_evaluated, intent})
  end

  defp call_intention_api(input) do
    evaluator = Application.get_env(:dobar, Intent.Evaluator)
    api = evaluator[:service] || @default_evaluator
    # "nil" represents the context wich was deprecated by wit.ai
    apply(api, :text_query, [input, nil])
  end
end
