defmodule Dobar.Robot do
  use GenServer

  alias Dobar.Interface
  alias Dobar.Conversation
  alias Dobar.Error.EvaluationError
  alias Dobar.Intent
  alias Dobar.Reaction
  alias Dobar.Effect

  def start_link(conf) do
    GenServer.start_link __MODULE__, conf
  end

  def new(robot_config) do
    Dobar.Robot.Supervisor.start_child(Dobar.Robot.Supervisor, robot_config)
  end

  def hear(robot, {:text, message}),  do: GenServer.cast robot, {:input, :text, message}
  def hear(robot, {:audio, message}), do: GenServer.cast robot, {:input, :audio, message}

  def say(robot, {:text, message}), do: GenServer.cast robot, {:output, :text, message}
  def say(robot, {:audio, message}), do: GenServer.cast robot, {:output, :audio, message}

  def handle_cast({:input, :text, message}, state) do
    # TODO: build a clear api for the interface module
    send state.interface, {:input, :text, message}
    # {_, pid, _, _} = get_child(state.supervisor, :interface)
    # Interface.Supervisor.process_input(pid, {:input, :text, message})
    {:noreply, state}
  end

  def handle_info({:evaluation_error, %EvaluationError{} = error}, state) do
    # message_responders(state.supervisor, error)
    {:noreply, state}
  end
  def handle_info({:evaluate_intent, %Intent{} = intent}, state) do
    # {_, pid, _, _} = get_child(state.supervisor, :conversation)
    # Conversation.react(pid, intent)
    # TODO: build a clear api for the conversation module
    send state.conversation, {:react, intent}
    {:noreply, state}
  end
  def handle_info({:dialog_reaction, %Reaction{} = reaction}, state) do
    effect = %Effect{reaction: reaction, responders: state.responders}
    Dobar.Effect.Runner.run(Dobar.Effect.Runner, effect, state.interface)
    {:noreply, state}
  end

  def init(conf) do
    {:ok, interface} = Interface.Supervisor.start_child Interface.Supervisor,
      [robot: self, adapter: conf[:adapter], evaluator: conf[:evaluator]]

    {:ok, conversation} = Conversation.Supervisor.start_child(Conversation.Supervisor,
      [robot: self, definitions: conf[:definitions]])

    {:ok, %{adapter: conf[:adapter],
            responders: conf[:effects],
            conversation: conversation,
            interface: interface}}
  end
end
