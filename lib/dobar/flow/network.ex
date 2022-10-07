defmodule Dobar.Flow.Network do
  use GenServer

  alias Dobar.Saga
  alias Dobar.Flow.Network.SchedulerSupervisor

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec create_flow(atom() | pid(), Saga.t()) :: term()
  def create_flow(server, saga) do
    GenServer.call(server, {:create, saga})
  end

  @impl true
  def init(_init_arg) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:create, saga}, _from, state) do
    {:ok, scheduler} = SchedulerSupervisor.start_scheduler(saga)
    {:reply, :ok, Map.put(state, saga.name, scheduler)}
  end
end
