defmodule Dobar.Flow.Network.Scheduler do
  use GenServer

  alias Dobar.Saga
  alias Dobar.Flow.Network

  @spec start_link(Saga.t()) :: term()
  def start_link(saga) do
    GenServer.start_link(__MODULE__, [for_saga: saga], name: via(saga))
  end

  def init(for_saga: %Dobar.Saga{} = saga) do
    {:ok, %{saga: saga}, {:continue, :init_connections}}
  end

  def handle_continue(:init_connections, state) do
    # {:ok, pid} = Network.ConnectionSupervisor.start_connection()
    # IO.inspect(Process.alive? pid)
    # GenServer.cast(pid, :foo)
    # Process.send_after(pid, :foo, 1000)

    connections =
      state.saga.connections
      |> Enum.map(fn c ->
        {
          c,
          #  DynamicSupervisor.start_child(
          #    Network.ConnectionSupervisor,
          #    {Network.Connection, []}
          #  )
          Network.ConnectionSupervisor.start_connection(c)
        }
      end)
      |> Enum.map(fn {c, {:ok, pid}} -> {c, pid} end)

    # output_ports = Network.ConnectionsMapper.output_ports(connections)
    # input_ports = Network.ConnectionsMapper.input_ports(connections)

    # IO.inspect(connections)
    # IO.inspect(output_ports)
    # IO.inspect(input_ports)

    state.saga.nodes
    |> Enum.each(fn node ->
      Network.NodeSupervisor.start_node(node: node)
    end)

    case state.saga.nodes |> Enum.find(fn n -> n.is_root end) do
      nil -> nil
      node -> execute_root_node(node)
    end

    {:noreply, state}
  end

  defp via(saga) do
    {:via, Registry, {Network.SchedulersRegistry, saga.name, saga.version}}
  end

  defp execute_root_node(node) do
    case Registry.lookup(Dobar.Flow.Network.NodesRegistry, node.id) do
      [{pid, _}] -> GenServer.cast(pid, :execute)
      _ -> nil
    end
  end
end
