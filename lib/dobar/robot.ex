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

  TODO: should validate the entire configuration before trying to start a new robot!
  """
  def start_link(conf) do
    GenServer.start_link __MODULE__, conf
  end

  @doc """
  Creates a new robot with the given config as keyword list or by giving
  the config namespace as atom.
  """
  def new(config) when is_list(config) do
    Dobar.Robot.Supervisor.start_robot(Dobar.Robot.Supervisor, config)
  end
  def new(robot) when is_atom(robot) do
    conf = Application.get_env(:dobar, robot)
    Dobar.Robot.Supervisor.start_robot(Dobar.Robot.Supervisor, conf)
  end

  @doc """
  Shuts down a robot given its process pid.
  """
  def shutdown(pid) do
    Dobar.Robot.Supervisor.shutdown_robot(Dobar.Robot.Supervisor, pid)
  end

  @doc """
  Tells the robot to react when receiving a text message.
  """
  def react(robot, {:text, message}),  do: GenServer.cast robot, {:input, :text, message}

  def handle_cast({:input, :text, message}, state) do
    send state.interface, {:input, :text, message}
    {:noreply, state}
  end

  def handle_info({:evaluate_intent, %Intent{} = intent}, state) do
    # send state.conversation, {:provide_intent, intent}
    Conversation.provide(state.conversation, intent)
    {:noreply, state}
  end
  def handle_info({:evaluation_error, %EvaluationError{} = error}, state) do
    effect = %Effect{error: error, responders: state.responders}
    Dobar.Effect.Runner.run(Dobar.Effect.Runner, effect, state.interface)
    {:noreply, state}
  end
  def handle_info({:dialog_reaction, %Reaction{} = reaction}, state) do
    effect = %Effect{reaction: reaction, responders: state.responders}
    Dobar.Effect.Runner.run(Dobar.Effect.Runner, effect, state.interface)
    {:noreply, state}
  end

  def init(conf) do
    interface_conf = [
      robot: self,
      adapter: conf[:adapter],
      evaluator: conf[:evaluator]
    ]
    {:ok, interface} = Interface.start_link interface_conf

    conversation_conf = [
      robot: self,
      definitions: conf[:definitions]
    ]
    {:ok, conversation} = Conversation.start_link conversation_conf

    # {:ok, interface} = Interface.Supervisor.start_child Interface.Supervisor,
    #   [robot: self, adapter: conf[:adapter], evaluator: conf[:evaluator]]

    # {:ok, conversation} = Conversation.Supervisor.start_child(Conversation.Supervisor,
    #   [robot: self, definitions: conf[:definitions]])

    {:ok, %{adapter: conf[:adapter],
            responders: conf[:effects],
            conversation: conversation,
            interface: interface}}
  end
end
