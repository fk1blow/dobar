defmodule Dobar.Flow.Network.Scheduler do
  use GenServer

  def start_link(for_saga: saga_name) do
    GenServer.start_link(__MODULE__, [for_saga: saga_name], name: via(saga_name))
  end

  def init(for_saga: saga_name) do
    {:ok, %{saga_name: saga_name}}
  end

  defp via(key) do
    {:via, Registry, {Dobar.Flow.Network.Scheduler.Registry, key}}
  end
end
