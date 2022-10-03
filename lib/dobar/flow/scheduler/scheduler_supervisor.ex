defmodule Dobar.Flow.Scheduler.SchedulerSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @spec start_node(Dobar.Saga.Node.t()) :: atom()
  def start_node(node) do
    DynamicSupervisor.start_child(__MODULE__, {node.module, node})
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end