defmodule Dobar.Intent.Resolver do
  @moduledoc """
  Has the responsability to resolve or transform a text expression, to an intent.
  It communicates with an external service in order to evaluate the input.
  Right now, the only current available service is wit.ai
  """

  use GenServer
  alias Dobar.Intent.Evaluator

  @name __MODULE__

  def start_link do
    GenServer.start_link __MODULE__, [], name: @name
  end

  def evaluate_input({:text, input}) do
    GenServer.cast @name, {:evaluate_input, input}
  end

  # callback functions
  #

  def handle_cast({:evaluate_intent, intent}, state) do
    # IO.puts "should evaluate intent: #{inspect intent}"
    # maybe, it should call:
    # Capability.evaluate_intent intent
    # or Kapyz.dispatcher something...
    {:noreply, state}
  end

  def handle_cast({:evaluate_input, input}, state) do
    Evaluator.evaluate_input {:text, input}
    {:noreply, state}
  end

  # initialization and private functions
  #

  def init(_) do
    start_intent_manager
    {:ok, nil}
  end

  defp start_intent_manager do
    import Supervisor.Spec, warn: false
    alias Dobar.Intent.ResolverHandler

    children = [
      worker(GenEvent, [[name: :intent_mananger]])
    ]
    opts = [strategy: :one_for_one]
    with {:ok, pid} <- Supervisor.start_link(children, opts),
          :ok <- GenEvent.add_handler(:intent_mananger, ResolverHandler, nil),
      do: :ok
  end
end
