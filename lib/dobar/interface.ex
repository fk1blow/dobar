defmodule Dobar.Interface do
  use GenServer
  alias Dobar.Interface.Adapter
  alias Dobar.Conversation.Intention.Evaluator, as: IntentionEvaluator

  def start_link(opts) do
    IO.puts "-----interface opts: #{inspect opts}"
    GenServer.start_link __MODULE__, opts
  end

  def init(args) do
    adapter =
      args[:adapter]
      |> validate_adapter
      |> start_adapter(self)
    case adapter do
      {:ok, adapter} ->
        {:ok, %{adapter: adapter, robot: args[:robot], evaluator: args[:evaluator]}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # received usually from a responder, after the conversation reacts
  def handle_info({:output, :text, message}, %{adapter: adapter} = state) do
    Kernel.send adapter, {:text, message}
    {:noreply, state}
  end
  # received from the adapter and used as a callback for input triggers
  def handle_info({:input, :text, message}, state) do
    case evaluate_text_input(message, state.evaluator) do
      {:ok, intent} ->
        send(state.robot, {:evaluate_intent, intent})
      {:error, reason} ->
        send(state.robot, {:evaluation_error, reason})
    end
    {:noreply, state}
  end

  # Private

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

  def start_adapter({:error, reason}, _, _) do
    {:stop, reason}
  end
  def start_adapter({:ok, adapter}, interface) do
    case Adapter.start_adapter(adapter, interface) do
      {:ok, pid} -> {:ok, pid}
      {:error, reason} -> {:stop, reason}
    end
  end

  defp evaluate_text_input(input, evaluator) do
    opts = evaluator
    service = evaluator[:service]
    IntentionEvaluator.evaluate {:text, input, service, evaluator}
  end
end
