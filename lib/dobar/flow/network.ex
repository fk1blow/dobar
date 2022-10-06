defmodule Dobar.Flow.Network do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec create_network(pid(), binary()) :: term()
  def create_network(server, saga) do
    # GenServer.call(server, {:create, saga})
  end

  @impl GenServer
  def init(init_arg) do
    {:ok, init_arg}
  end
end
