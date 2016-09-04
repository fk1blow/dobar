defmodule Dobar.Interface.Adapter.Console do
  use Dobar.Interface.Adapter

  alias Dobar.Interface.Adapter.Console.Connection

  def start_link(opts) do
    GenServer.start_link __MODULE__, [adapter: opts[:adapter_proc]], name: __MODULE__
  end

  def init(args) do
    {:ok, connection} = Connection.start_link([adapter: args[:adapter]])
    {:ok, %{connection: connection}}
  end

  # ????????
  def send(message) do
    GenServer.call __MODULE__, {:send, message}
  end

  def handle_call({:send, message}, _from, state) do
    Connection.send state.connection, message
    {:noreply, state}
  end
end
