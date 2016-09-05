defmodule Dobar.Interface.Adapter.Console do
  use Dobar.Interface.Adapter

  alias Dobar.Interface.Adapter.Console.Connection

  def start_link(opts) do
    GenServer.start_link __MODULE__, opts, name: __MODULE__
  end

  def init(args) do
    {:ok, %{connection: nil, adapter: args[:adapter_interface]}}
  end

  def send(:text, message) do
    GenServer.cast __MODULE__, {:send, :text, message}
  end

  def handle_cast({:send, :text, message}, state) do
    IO.puts "adapter should send message to connection, message: #{inspect message}"
    # Connection.send state.connection, message
    {:noreply, state}
  end

  def handle_info({:connect, opts}, state) do
    {:ok, connection} = Connection.start_link([adapter: state.adapter])
    {:noreply, Map.merge(state, %{connection: connection})}
  end
end
