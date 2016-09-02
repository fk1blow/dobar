defmodule Dobar.Interface.Adapter.Console do
  use Dobar.Interface.Adapter

  alias Dobar.Interface.Adapter.Console.Connection

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    {:ok, connection} = Connection.start_link
    {:ok, %{connection: connection, adapter: nil}}
  end

  def send(message) do
    GenServer.call __MODULE__, {:send, message}
  end

  def handle_call({:send, message}, _from, state) do
    Connection.send state.connection, message
    {:noreply, state}
  end
end
