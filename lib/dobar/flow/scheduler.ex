defmodule Dobar.Flow.Scheduler do
  alias Dobar.Flow.Network
  alias Dobar.Flow.Scheduler.SchedulerSupervisor

  @registry Dobar.Flow.Scheduler.Registry

  def start_link(name: name) do
    GenServer.start_link(__MODULE__, [], name: name)
  end

  @spec start_network(atom(), Network.t()) :: term()
  def start_network(server, network) do
    GenServer.cast(server, {:start_network, network})

    # network.nodes
    # |> Enum.each(fn node -> SchedulerSupervisor.start_node(node) end)

    # # need to activate the root node
    # root_node = network.nodes
    # |> Enum.find(fn node -> node.is_root === true end)
    # # |> Enum.each(fn node -> GenServer.call({:via, Registry, {@registry, node.name}}, :execute) end)

    # IO.inspect root_node.name

    # nil
  end

  def init(_args) do
    {:ok, %{nodes: []}}
  end

  def handle_cast({:start_network, network}, state) do
    # IO.inspect(network)

    # res = GenServer.start(Dobar.Flow.Port, [])
    # IO.inspect res

    ports =
      network.connections
      |> Enum.map(fn c -> {c, GenServer.start(Dobar.Flow.Port, [])} end)
      |> Enum.map(fn {c, {:ok, pid}} -> {c, pid} end)

    output_ports =
      ports
      |> Enum.reduce(%{}, fn {conn, pid}, acc ->
        if Map.has_key?(acc, conn.from) do
          %{acc | conn.from => Map.put(acc[conn.from], conn.to, pid)}
        else
          Map.put(acc, conn.from, %{conn.to => pid})
        end
      end)

    input_ports =
      ports
      |> Enum.reduce(%{}, fn {conn, pid}, acc ->
        if Map.has_key?(acc, conn.to) do
          %{acc | conn.to => Map.put(acc[conn.to], conn.from, pid)}
        else
          Map.put(acc, conn.to, %{conn.from => pid})
        end
      end)

    IO.inspect(input_ports)
    IO.inspect(output_ports)

    network.nodes
    |> Enum.each(fn node ->
      # IO.inspect "starting node: #{node.name}"
      SchedulerSupervisor.start_node(node)
      # SchedulerSupervisor.start_node([
      #   node: node,
      #   input_ports: input_ports,
      #   output_ports: output_ports
      # ])
    end)

    # no need to find root node b/c they're self reliant
    # root_node = network.nodes |> Enum.find(fn node -> node.is_root === true end)
    # IO.inspect(root_node)

    # no need to execute nodes b/c they're self reliant
    # case root_node do
    #   nil -> IO.puts("no root node")
    #   node -> GenServer.call({:via, Registry, {@registry, node.name}}, :execute)
    # end

    # |> Enum.each(fn node -> GenServer.call({:via, Registry, {@registry, node.name}}, :execute) end)

    # activate the root node
    {:noreply, Map.put(state, :nodes, network.nodes)}
  end
end
