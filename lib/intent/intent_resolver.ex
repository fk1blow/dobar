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

  def evaluate_input({:text, input}) do
    GenServer.cast @name, {:evaluate_input, input}
  end

  def evaluate_intent(intent) do
    GenServer.cast @name, {:evaluate_intent, intent}
  end

  # callback functions
  #

  def handle_cast({:evaluate_input, input}, state) do
    IntentEvaluator.evaluate_input {:text, input}
    {:noreply, state}
  end

  def handle_cast({:evaluate_intent, intent}, state) do
    KapyzDispatcher.evaluate_intent intent
    {:noreply, state}
  end

  # initialization and private functions
  #

  def init(_) do
    start_intent_manager
    {:ok, nil}
  end

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
