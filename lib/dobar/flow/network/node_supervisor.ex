defmodule Dobar.Flow.Network.NodeSupervisor do
  use DynamicSupervisor

  @type start_args :: [node: Dobar.Saga.Node.t()]

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec start_node(start_args) :: DynamicSupervisor.on_start_child()
  def start_node(node: node) do
    DynamicSupervisor.start_child(__MODULE__, {node_to_module(node), [node: node]})
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp node_to_module(node), do: String.to_atom("Elixir." <> node.component)
end
