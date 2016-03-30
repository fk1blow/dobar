defmodule Dobar.Spub.IntentHandler do
  @moduledoc """
  Has the responsability to handle events and notifications related to an intent.
  An intent is/represents an expression that was evaluated and its intention was detected.
  """

  require Logger

  use GenEvent

  # triggered from `Intent.Evaluator`
  def handle_event({:intention_evaluation_error, error}, state) do
    # TODO: what should i do with this?!?! can i signal the interface user?
    # What message should i send him, the plain error, something else?!
    Logger.info "error while trying to evaluate the input intent: #{inspect error}"
    {:ok, state}
  end

  # triggered from `Intent.Evaluator`
  def handle_event({:intention_evaluated, intent}, state) do
    Logger.info "intention evaluated to: #{inspect intent}"
    Dobar.Intent.Resolver.evaluate_intent intent
    {:ok, state}
  end

  def handle_event({:capability_evaluated, capability}, state) do
    Logger.info "capability evaluated to: #{inspect capability}"
    Dobar.Intent.Resolver.evaluate_capability capability
    {:ok, state}
  end
end

