defmodule Dobar.Intent.Resolver do
  @moduledoc """
  Has the responsability to resolve or transform a text expression, to an intent.
  It communicates with an external service in order to evaluate the input.
  Right now, the only current available service is wit.ai
  """

  use GenServer
  import Dobar.Intent.Evaluator

  @name __MODULE__

  def start_link do
    GenServer.start_link __MODULE__, [], name: @name
  end

  def evaluate_input({:text, input}) do
    GenServer.cast @name, {:evaluate_input, input}
  end

  def handle_cast({:evaluate_input, input}, state) do
    evaluate_intention {:text, input}
    {:noreply, state}
  end

  def init(_) do
    {:ok, nil}
  end
end
