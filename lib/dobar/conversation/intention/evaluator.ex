defmodule Dobar.Conversation.Intention.Evaluator do
  @moduledoc """
  Conversation Intention Evaluator

  It extracts the intent from an input(text, for now) and outputs an
  %Intent struct the intent representation

  To evaluate the input, it needs a service that knows how to evaluate
  such types of input, services like wit.ai - default, for now
  """

  alias Dobar.Model.Intent

  @default_evaluator Dobar.Conversation.Intention.Evaluator.Wit

  def evaluate({:text, input, evaluator, opts}),
    do: evaluator |> do_evaluate(@default_evaluator, :text_query, input, opts) |> parse

  # "nil" represents the context wich was deprecated by wit.ai
  defp do_evaluate(nil, default_evaluator, input_type, input, opts),
    do: apply(default_evaluator, input_type, [input, opts])
  defp do_evaluate(evaluator, _default_evaluator, input_type, input, opts),
    do: apply(evaluator, input_type, [input, opts])

  defp parse({:error, error}), do: {:error, error}
  defp parse({:ok, intention}) do
    intent = hd intention.outcomes
    {:ok, %Intent{name: intent.intent, input: intent._text,
      entities: intent.entities, confidence: intent.confidence}}
  end
end
