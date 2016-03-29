defmodule Dobar.Intent.Resolver do
  @moduledoc """
  Has the responsability to resolve or transform a text expression, to an intent.
  It communicates with an external service in order to evaluate the input.
  Right now, the only current available service is wit.ai
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
    {:ok, %{dialog: nil}}
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
    IntentEvaluator.evaluate_input {:text, input, state: state.dialog}
    {:noreply, state}
  end

  def handle_cast({:evaluate_intent, intent}, state) do
    KapyzDispatcher.evaluate_intent intent
    {:noreply, state}
  end

  def handle_cast({:evaluate_capability, capability}, state) do
    IO.puts "intent resolver should evaluate the capability and shit"

    case capability do
      %{dialog: dialog} -> state = %{dialog: capability[:dialog]}
      %{response: response} -> state = %{dialog: nil}
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

    children = [
      worker(GenEvent, [[name: :intent_events]])
    ]
    opts = [strategy: :one_for_one]
    with {:ok, pid} <- Supervisor.start_link(children, opts),
          :ok <- GenEvent.add_handler(:intent_events, IntentHandler, nil),
      do: :ok
  end
end
