defmodule Dobar.Intent.Evaluator do
  @moduledoc """
    It extracts the intent from an input(text, for now) and outputs an
    %Intent struct the intent representation

    To evaluate the input, it needs a service that knows how to evaluate
    such types of input, services like wit.ai - default, for now

    TODO: see if making this module a genserver would make it more reliable
    and concise - self healing(through supervision), better api clarity, etc
  """

  alias Dobar.Models.Intent

  def evaluate_input({:text, input}) do
    intent = apply(show_wrapper, :text_query, [input])
    |> parse_response
    |> parse_intention
    |> notify_handlers
  end

  defp parse_response({:error, error}), do: {:error, error}
  defp parse_response({:ok, intention}), do: {:ok, intention}

  defp parse_intention({:error, error}), do: {:error, error}
  defp parse_intention({:ok, intention}) do
    intent = hd intention.outcomes
    {:ok, %Intent{name: intent.intent, input: intent._text,
      entities: intent.entities, confidence: intent.confidence}}
  end

  defp notify_handlers({:error, error}) do
    GenEvent.notify(:intent_events, {:intention_evaluation_error})
  end
  defp notify_handlers({:ok, intent}) do
    GenEvent.notify(:intent_events, {:intention_evaluated, intent})
  end

  defp show_wrapper do
    evaluator = Application.get_env(:dobar, Intent.Evaluator)
    evaluator[:use_wrapper] || Dobar.Intent.Evaluator.Wit
  end
end
