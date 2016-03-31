defmodule Dobar.Spub.IntentHandler do
  @moduledoc """
  Has the responsability to handle events and notifications related to an intent.
  An intent is/represents an expression that was evaluated - its intention was determined.
  """

  require Logger

  use GenEvent

  alias Dobar.Model.Capability
  alias Dobar.Model.Intent

  # triggered from `Interface.Controller`
  def handle_event({:text_input_evaluated, input}, _state) do
    Logger.info "text input evaluated to: #{input}"
    {:ok, nil}
  end

  # triggered from `Intent.Evaluator`
  def handle_event({:intention_evaluation_error, error}, _state) do
    # TODO: what should i do with this?!?! can i signal the interface user?
    # What message should i send him, the plain error, something else?!
    Logger.info "error while trying to evaluate the input intent: #{inspect error}"
    {:ok, nil}
  end

  # triggered from `Intent.Evaluator`
  def handle_event({:intention_evaluated, %Intent{} = intent}, _state) do
    Logger.info "intention was evaluated to: #{inspect intent.name}"
    Dobar.Intent.Resolver.evaluate_intent intent
    {:ok, nil}
  end

  # triggered from `Kapyz.Capability.SendMessage`
  def handle_event({:capability_evaluated, %Capability{} = capability}, _state) do
    Logger.info "capability was evaluated to: #{inspect capability}"
    Dobar.Intent.Resolver.evaluate_capability capability
    {:ok, nil}
  end

  # TODO: this is the place where the `context` and `intent` will arrive
  # def handle_event({:capability_evaluated, capability}, _state) do
  #   Logger.info "capability was evaluated to: #{inspect capability}"
  #   Dobar.Intent.Resolver.evaluate_capability capability
  #   {:ok, nil}
  # end
end

