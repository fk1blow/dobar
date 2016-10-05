defmodule Dobar.Interface do
  use GenServer

  require Logger

  alias Dobar.EvaluationError
  alias Dobar.Interface.Adapter
  alias Dobar.Conversation.Intention.Evaluator, as: IntentionEvaluator

  def start_link(opts) do
    GenServer.start_link __MODULE__, opts
  end

  def init(args) do
    case adapter = args[:adapter] |> validate_adapter |> start_adapter(self) do
      {:ok, adapter} ->
        {:ok, %{adapter: adapter, robot: args[:robot], evaluator: args[:evaluator]}}
      {:error, reason} ->
        {:stop, reason}
    end
  end

  # the :output comes from a responder, when the user decides it wants to reply
  # to the interface, and the :input comes from the adapter, when the user inputs
  def handle_info({:output, :text, message}, %{adapter: adapter} = state) do
    Kernel.send adapter, {:text, message}
    {:noreply, state}
  end
  def handle_info({:input, :text, message}, state) do
    case evaluate_text_input(message, state.evaluator) do
      {:ok, intent} ->
        send(state.robot, {:evaluate_intent, intent})
      {:error, reason} ->
        Logger.info("intent evaluation error, reason: #{inspect reason}")
        send(state.robot, {:evaluation_error, %EvaluationError{reason: reason}})
    end
    {:noreply, state}
  end

  defp validate_adapter(adapter) do
    case adapter do
      nil -> {:error, "Cannot start the interface without an adapter!"}
      adapter ->
        case Code.ensure_loaded?(adapter) do
          true -> {:ok, adapter}
          false -> {:error, "Cannot start the interface without an adapter!"}
        end
    end
  end

  def start_adapter({:error, reason}, _) do
    {:error, reason}
  end
  def start_adapter({:ok, adapter}, interface) do
    case Adapter.start_adapter(adapter, interface) do
      {:ok, pid} -> {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end

  defp evaluate_text_input(input, evaluator) do
    service = evaluator[:service]
    IntentionEvaluator.evaluate {:text, input, service, evaluator}
  end
end
