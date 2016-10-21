defmodule Dobar.Robot do
  use GenServer

  alias Dobar.Interface
  alias Dobar.Conversation
  alias Dobar.Error.EvaluationError
  alias Dobar.Intent
  alias Dobar.Reaction
  alias Dobar.Effect

  @doc """
  Start a new robot with the given configuration keyword list.
  """
  def start_link(conf) do
    GenServer.start_link __MODULE__, conf, name: via_tuple(conf[:name])
  end

  @doc """
  It creates a new robot with the given configuration and an additional
  optional keyword list.
  """
  def new(config, opts \\ []) when is_list(config) and is_list(opts) do
    config = config |> Keyword.merge(opts)
    Dobar.Robot.Supervisor.start_robot(Dobar.Robot.Supervisor, config)
  end

  @doc """
  Shuts down a robot given its process pid.
  """
  def shutdown(robot) do
    case Dobar.Robot.Registry.whereis_name(robot) do
      :undefined ->
        {:error, "cannot stop undefined robot #{inspect robot}"}
      robot ->
        Dobar.Robot.Registry.unregister_name(robot)
        Dobar.Robot.Supervisor.shutdown_robot(Dobar.Robot.Supervisor, robot)
    end
  end

  @doc """
  Tells the robot to react when receiving a text message.
  """
  def say(robot, {:text, message}) do
    GenServer.cast via_tuple(robot), {:input, :text, message}
  end

  def init(conf) do
    with {:ok, interface} = Interface.start_adapter(conf[:adapter]),
         {:ok, conversation} = Conversation.start_link([
           robot: self,
           definitions: conf[:definitions]]),
    do
      {:ok, %{adapter: conf[:adapter],
              responders: conf[:effects],
              evaluator: conf[:evaluator],
              conversation: conversation,
              interface: interface}}
    else
      {:error, reason} ->
        {:stop, reason}
      _ ->
        {:stop, "unknown reason"}
    end

    # {:ok, interface} = Interface.start_link([
    #   robot: self,
    #   adapter: conf[:adapter],
    #   evaluator: conf[:evaluator]])

    # {:ok, conversation} = Conversation.start_link([
    #   robot: self,
    #   definitions: conf[:definitions]])

    # {:ok, %{adapter: conf[:adapter],
    #         responders: conf[:effects],
    #         evaluator: conf[:evaluator],
    #         conversation: conversation,
    #         interface: interface}}
  end

  def handle_cast({:input, :text, message}, state) do
    send state.interface, {:input, :text, message}
    {:noreply, state}
  end

  def handle_info({:intent_evaluated, %Intent{} = intent}, state) do
    Conversation.forward(state.conversation, intent)
    {:noreply, state}
  end
  def handle_info({:evaluation_error, %EvaluationError{} = error}, state) do
    effect = %Effect{error: error, responders: state.responders}
    Dobar.Effect.Runner.run(Dobar.Effect.Runner, effect, state.interface)
    {:noreply, state}
  end
  def handle_info({:dialog_reaction, %Reaction{} = reaction}, state) do
    effect = %Effect{reaction: reaction, responders: state.responders}
    Effect.Runner.run(Dobar.Effect.Runner, effect, state.interface)
    {:noreply, state}
  end
  def handle_info({:output, :text, message}, %{adapter: adapter} = state) do
    Kernel.send adapter, {:text, message}
    {:noreply, state}
  end
  def handle_info({:input, :text, message}, state) do
    case Interface.evaluate_input(message, state.evaluator) do
      {:ok, intent} ->
        send(state.robot, {:intent_evaluated, intent})
      {:error, reason} ->
        send(state.robot, {:evaluation_error, %EvaluationError{reason: reason}})
    end
    {:noreply, state}
  end

  defp via_tuple(name) do
    {:via, Dobar.Robot.Registry, name}
  end
end
