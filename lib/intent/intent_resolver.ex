defmodule Dobar.Intent.Resolver do
  use GenServer

  alias Dobar.Intent.Evaluator, as: IntentEvaluator
  alias Dobar.Model.Input.Text, as: TextInput
  alias Dobar.Model.Input.Audio, as: AudioInput
  alias Dobar.Model.Capability
  alias Dobar.Spub.IntentHandler

  @name __MODULE__

  def start_link do
    GenServer.start_link @name, [], name: @name
  end

  def init(_) do
    GenEvent.add_handler(:intent_events, IntentHandler, nil)
    {:ok, nil}
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

  def handle_cast({:evaluate_input, input}, _) do
    IntentEvaluator.evaluate_input {:text, input}
    {:noreply, nil}
  end

  def handle_cast({:evaluate_intent, intent}, _) do
    Dobar.Dialog.GenericDialog.evaluate :root_dialog, intent
    {:noreply, nil}
  end
end
