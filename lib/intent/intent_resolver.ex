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

  @name __MODULE__

  def start_link do
    GenServer.start_link @name, [], name: @name
  end

  def init(_) do
    GenEvent.add_handler(:intent_events, IntentHandler, nil)
    {:ok, %{context: Map.new}}
  end

  def evaluate_input(%TextInput{data: input}) do
    GenServer.cast @name, {:evaluate_input, input}
  end
  def evaluate_input(%AudioInput{data: input}) do
    raise "cannot evaluate audio input, just yet!"
  end

  def evaluate_intent(intent) do
    GenServer.cast @name, {:evaluate_intent, intent}
  end

  def evaluate_capability(capability) do
    GenServer.cast @name, {:evaluate_capability, capability}
  end

  # callback functions
  #

  def handle_cast({:evaluate_input, input}, state) do
    # HERE BE dragons n shit
    IntentEvaluator.evaluate_input {:text, input, state.context}
    {:noreply, state}
  end

  # This won't treat the error in case an intent wasn't evaluated
  # TODO: define the case for which an intent has errord
  def handle_cast({:evaluate_intent, intent}, state) do
    KapyzDispatcher.evaluate_intent intent
    {:noreply, state}
  end

  def handle_cast({:evaluate_capability, capability}, state) do
    IO.puts "intent resolver should evaluate the capability and shit"

    case capability do
      %{dialog: dialog} -> state = %{context: capability[:dialog]}
      %{response: response} -> state = %{context: Map.new}
      _ -> IO.puts "pfff, dunno man, dunno"
    end

    {:noreply, state}
  end
end
