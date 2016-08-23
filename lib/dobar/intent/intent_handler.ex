defmodule Dobar.Intent.IntentHandler do
  @moduledoc """
  Has the responsability to handle events and notifications related to an intent.
  An intent is/represents an expression that was evaluated - its intention was determined.
  """

  require Logger

  use GenEvent

  alias Dobar.Model.Capability
  alias Dobar.Model.Intent

  # triggered from `Interface.Controller`
  def handle_event({:input_intent_parsed, input}, _state) do
    Logger.info "text input evaluated to: #{inspect input}"
    Dobar.Intent.Resolver.evaluate_input input
    {:ok, nil}
  end

  # triggered from `Intent.Evaluator`
  def handle_event({:intention_evaluation_error, error}, _state) do
    # TODO: what should i do with this?!?! can i signal the interface user?
    # What message should i send him, the plain error, something else?!
    # Update: yes, you can send a message(output) to the user, possibly mentioning
    # the reason for this
    Logger.info "error while trying to evaluate the input intent: #{inspect error}"
    {:ok, nil}
  end

  # triggered from `Intent.Evaluator`
  def handle_event({:intention_evaluated, %Intent{} = intent}, _state) do
    Logger.info "intention evaluated to: #{inspect intent.name}"
    Dobar.Intent.Resolver.evaluate_intent intent
    {:ok, nil}
  end
end

