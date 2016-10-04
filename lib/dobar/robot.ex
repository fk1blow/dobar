defmodule Dobar.Robot do
  use GenServer

  alias Dobar.Interface
  alias Dobar.Conversation
  alias Dobar.Responder
  alias Dobar.Intent
  alias Dobar.Reaction

  def start_link(opts) do
    GenServer.start_link __MODULE__, opts
  end

  def say(robot, {:text, message}),  do: GenServer.cast robot, {:input, :text, message}
  def say(robot, {:audio, message}), do: GenServer.cast robot, {:input, :audio, message}

  def init(conf) do
    case Code.ensure_loaded?(conf[:conversation]) do
      false ->
        {:error, "conversation definition module not found"}
      true ->
        {:ok, pid} = create_robot(conf)
        {:ok, %{supervisor: pid}}
    end
  end

  def handle_cast({:input, :text, message}, state) do
    {_, pid, _, _} = get_child(state.supervisor, :interface)
    Interface.Supervisor.process_input(pid, {:input, :text, message})
    {:noreply, state}
  end

  def handle_info({:evaluate_intent, %Intent{} = intent}, state) do
    {_, pid, _, _} = get_child(state.supervisor, :conversation)
    Conversation.react(pid, intent)
    {:noreply, state}
  end
  def handle_info({:evaluation_error, reason}, state) do
    IO.puts "______________:evaluation_error; reason: #{inspect reason}"
    {:noreply, state}
  end
  def handle_info({:dialog_reaction, %Reaction{} = reaction}, state) do
    {_, responder, _, _} = get_child(state.supervisor, :responder)
    {_, interface, _, _} = get_child(state.supervisor, :interface)
    Responder.Supervisor.respond(responder, {reaction, interface})
    {:noreply, state}
  end

  defp get_child(sup, type) do
    sup
    |> Supervisor.which_children
    |> Enum.find(nil, fn x -> elem(x, 0) == type end)
  end

  defp create_robot(conf) do
    import Supervisor.Spec

    children = [
      # start the interface supervisor
      supervisor(Interface.Supervisor,
        [[robot: self, adapter: conf[:adapter], evaluator: conf[:evaluator]]],
        id: :interface),

      # start the conversation manager
      worker(Conversation,
        [[robot: self, definitions: conf[:conversation]]],
        id: :conversation),

      # start the responder supervisor
      supervisor(Responder.Supervisor,
        [[interface_module: Interface.Supervisor,
          responders: conf[:responders]]],
        id: :responder)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
