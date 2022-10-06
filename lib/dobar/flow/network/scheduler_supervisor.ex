defmodule Dobar.Flow.Network.SchedulerSupervisor do
  use DynamicSupervisor

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  # @spec start_node(Dobar.Saga.Node.t()) :: atom()
  # TODO define the parameters of the `start_scheduler` function to accept saga
  # connections, nodes, etc, etc
  def start_scheduler(name) do
    DynamicSupervisor.start_child(__MODULE__, {Dobar.Flow.Network.Scheduler, node})
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
