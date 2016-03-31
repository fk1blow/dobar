defmodule Dobar.Intent.Resolver do
  @moduledoc """
  Has the responsability to evaluate an input to an intent using the capability module.
  It provides 3 api functions for each step - user input, intent evaluation and
  capability evaluation.
  This module (Intent) isn't responsible for the output that must reach the user!
  """

  use GenServer

  alias Dobar.Intent.Evaluator, as: IntentEvaluator
  alias Dobar.Kapyz.Dispatcher, as: KapyzDispatcher
  alias Dobar.Model.Input.Text, as: TextInput
  alias Dobar.Model.Input.Text, as: AudioInput
  alias Dobar.Model.Capability
  alias Dobar.Spub.IntentHandler

  @name __MODULE__

  def start_link do
    GenServer.start_link @name, [], name: @name
  end

  def init(_) do
    GenEvent.add_handler(:intent_events, IntentHandler, nil)
    {:ok, %Capability{}}
  end

  def evaluate_input(%TextInput{data: input}) do
    GenServer.cast @name, {:evaluate_input, input}
  end
  def evaluate_input(%AudioInput{data: input}) do
    raise "cannot evaluate audio input, just yet!"
  end

  # called from `Spub.IntentHandler`
  def evaluate_intent(intent) do
    GenServer.cast @name, {:evaluate_intent, intent}
  end

  # called from `Spub.IntentHandler`
  def evaluate_capability(capability) do
    GenServer.cast @name, {:evaluate_capability, capability}
  end

  # callback functions
  #

  def handle_cast({:evaluate_input, input}, state) do
    IntentEvaluator.evaluate_input {:text, input, state.context}
    {:noreply, state}
  end

  def handle_cast({:evaluate_intent, intent}, state) do
    KapyzDispatcher.evaluate_intent state.intent, intent
    {:noreply, state}
  end

  def handle_cast({:evaluate_capability, %Capability{} = capability}, _) do
    {:noreply, capability}
  end
end
