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

  @name __MODULE__

  def start_link do
    GenServer.start_link @name, [], name: @name
  end

  def init(_) do
    start_intent_manager
    {:ok, %{context: Map.new}}
  end

  def evaluate_input({:text, input}) do
    GenServer.cast @name, {:evaluate_input, input}
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

  # private functions
  #

  # TODO: maybe i should add the child to the intent supervisor instead
  defp start_intent_manager do
    import Supervisor.Spec, warn: false
    alias Dobar.Spub.IntentHandler
    alias Dobar.Spub.CapabilityHandler

    children = [
      worker(GenEvent, [[name: :intent_events]])
    ]
    opts = [strategy: :one_for_one]
    with {:ok, pid} <- Supervisor.start_link(children, opts),
          :ok <- GenEvent.add_handler(:intent_events, IntentHandler, nil),
      do: :ok
  end
end
