defmodule Dobar.Robot do
  # do i really need a server for this? should i use a supervisor only, instead?
  use GenServer
  # use Supervisor

  alias Dobar.Interface
  alias Dobar.Conversation
  alias Dobar.Intent
  alias Dobar.Reaction

  def start_link(opts \\ []) do
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
    case get_child(state.supervisor, :interface_supervisor) do
      nil ->
        IO.puts "______________: cannot handle text input with no available interface"
      {_, name, _, _} when is_pid(name) or is_atom(name) ->
        Interface.Supervisor.process_input(name, {:input, :text, message})
    end
    {:noreply, state}
  end

  def handle_info({:evaluate_intent, %Intent{} = intent}, state) do
    case get_child(state.supervisor, :conversation) do
      nil ->
        IO.puts "______________: cannot evaluate the intent with no available conversation"
      {_, name, _, _} when is_pid(name) or is_atom(name) ->
        Conversation.react(name, intent)
    end
    {:noreply, state}
  end
  def handle_info({:evaluation_error, reason}, state) do
    IO.puts "______________:evaluation_error; reason: #{inspect reason}"
    {:noreply, state}
  end
  def handle_info({:dialog_reaction, %Reaction{} = reaction}, state) do
    IO.puts "dialoooooooooooooooog reaaaaaaaaactiooooooon"
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
        id: :interface_supervisor),

      # start the conversation manager
      supervisor(Conversation,
        [[robot: self, definitions: conf[:conversation]]],
        id: :conversation),
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
