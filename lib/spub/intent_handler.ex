defmodule Dobar.Spub.IntentHandler do
  @moduledoc """
    Has the responsability to handle events and notifications related to an intent.
    An intent is an expression that was evaluated and its intention was detected.

    TODO: should be renamed to intent parser handler and break the parsing
    from the processing(coming as a result of the capability) stages in two
    distinct event handlers
      - when the response from wit.ai has arrived
      - when the capability has resolved the intention
  """

  require Logger

  use GenEvent

  def handle_event({:intention_evaluation_error, error}, state) do
    # TODO: what should i do with this?!?! can i signal the interface user?
    # What message should i send him the plain error?!
    Logger.info "error while trying to evaluate the input intent"
    {:ok, state}
  end

  # triggered from `Intent.Evaluator`
  def handle_event({:intention_evaluated, intent}, state) do
    Dobar.Intent.Resolver.evaluate_intent intent
    Logger.info "intention evaluated to: #{inspect intent}"
    {:ok, state}
  end

  def handle_event({:capability_evaluated, capability}, state) do
    Logger.debug "should distribute the results of the capability"
    {:ok, state}
  end
end

