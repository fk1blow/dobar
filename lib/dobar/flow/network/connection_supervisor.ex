defmodule Dobar.Flow.Network.ConnectionSupervisor do
  use DynamicSupervisor

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec start_connection(Dobar.Saga.Connection.t()) :: atom()
  def start_connection(conn) do
    DynamicSupervisor.start_child(__MODULE__, {Dobar.Flow.Network.Connection, conn})
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
