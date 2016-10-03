defmodule Dobar.Robot do
  # do i really need a server for this? should i use a supervisor only, instead?
  use GenServer
  # use Supervisor

  alias Dobar.Interface
  alias Dobar.Model.Intent

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
        # {:ok, pid} = Dobar.Conversation.Supervisor.start_link
        # {:ok, pid} = Interface.Supervisor.start_link([adapter: conf[:adapter]])

        {:ok, pid} = create_robot(conf)
        {:ok, %{supervisor: pid}}

        # {:ok, pid} = InterfaceSup.start_link([adapter: opts[:adapter]])
        # create_robot(conf)
    end
  end

  def handle_cast({:input, :text, message}, state) do
    case get_child(state.supervisor, :interface_supervisor) do
      nil ->
        raise "cannot handle text input because the interface is unavailable"
      {_, pid, _, _} when is_pid(pid) ->
        Dobar.Interface.Supervisor.process_input(pid, {:input, :text, message})
      {_, name, _, _} when is_atom(name) ->
        Dobar.Interface.Supervisor.process_input(name, {:input, :text, message})
    end
    {:noreply, state}
  end

  def handle_info({:evaluate_intent, %Intent{} = intent}, state) do
    case get_child(state.supervisor, :conversation) do
      nil ->
        raise "cannot evaluate the intent because the conversation managers i unavailable"
      {_, name, _, _} when is_pid(name) or is_atom(name) ->
        Dobar.Conversation.react(name, intent)
    end
    {:noreply, state}
  end
  def handle_info({:evaluation_error, reason}, state) do
    raise ":evaluation_error; reason: #{inspect reason}"
    {:noreply, state}
  end

  defp get_child(sup, type) do
    sup
    |> Supervisor.which_children
    |> Enum.find(nil, fn x -> elem(x, 0) == type end)
  end

  defp create_robot(conf) do
    import Supervisor.Spec

    evaluator = conf[:evaluator]
    adapter = conf[:adapter]

    children = [
      supervisor(Dobar.Conversation, [[robot: self]], id: :conversation),

      supervisor(Dobar.Interface.Supervisor,
        [[robot: self, adapter: adapter, evaluator: evaluator]],
        id: :interface_supervisor),

      # worker(evaluator_service_mod, [evaluator])
      # Start the Responder
      # supervisor(Dobar.Responder.Supervisor, [[interface: Dobar.Interface]]),

      # supervisor(Dobar.Interface.Supervisor, [], id: :interface_supervisor)

      # Start the events manager used by interface and Conversation api
      # worker(GenEvent, [], id: :input_manager),

      # Start events manager used by the dialog and conversation api
      # worker(GenEvent, [], id: :dialog_manager),

      # Start the interface of the dialog system
      # TO BE REFACTORED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      # worker(Dobar.Interface, [[
      #   # event_manager: Dobar.InterfaceEvents,
      #   event_manager: interface_events_ref,
      #   # interface_conf: Dobar.Conversation
      #   interface_conf: [adapter: opts[:adapter]]
      # ]]),

      # supervisor(Dobar.Interface.Supervisor)

      # Start the conversation definition provided by the user via config
      # worker(conversation_definition, [], id: opts[:interface_ref])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
