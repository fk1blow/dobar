# TODO: this module needs massive refactoring.
# First of all, it doesn't need to store the 'adapter' and the 'evaluator' because
# each of them can be read from the application env.
# Secondly, the only thing needed now is the `robot` process ref that could easily
# be passed directly to the adapter(and so you can send message directly to it,
# completely avoiding the interface module)
defmodule Dobar.Interface do
  use GenServer

  alias Dobar.Error.EvaluationError
  alias Dobar.Interface.Adapter
  alias Dobar.Conversation.Intention.Evaluator, as: IntentionEvaluator

  def start_link(conf) do
    GenServer.start_link __MODULE__, conf
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
  # to the interface, and the :input comes from the user through the adapter
  def handle_info({:output, :text, message}, %{adapter: adapter} = state) do
    Kernel.send adapter, {:text, message}
    {:noreply, state}
  end
  def handle_info({:input, :text, message}, state) do
    case evaluate_text_input(message, state.evaluator) do
      {:ok, intent} ->
        send(state.robot, {:intent_evaluated, intent})
      {:error, reason} ->
        send(state.robot, {:evaluation_error, %EvaluationError{reason: reason}})
    end
    {:noreply, state}
  end

  defp validate_adapter(adapter_conf) do
    case adapter_mod = adapter_conf[:module] do
      nil -> {:error, "Cannot start the interface without an adapter!"}
      adapter ->
        case Code.ensure_loaded?(adapter_mod) do
          true -> {:ok, adapter_conf}
          false -> {:error, "Cannot start the interface without an adapter!"}
        end
    end
  end

  def start_adapter({:error, reason}, _), do: {:error, reason}
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
