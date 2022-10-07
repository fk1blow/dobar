defmodule Dobar.Flow.Network.SchedulerSupervisor do
  use DynamicSupervisor

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_scheduler(saga = %Dobar.Saga{}) do
    DynamicSupervisor.start_child(__MODULE__, {Dobar.Flow.Network.Scheduler, saga})
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
