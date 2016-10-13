defmodule Dobar.Interface.Adapter.Console do
  @moduledoc """
  Interface Console Adapter

  An interface adapter for the terminal.
  """

  alias Dobar.Interface.Adapter.Console.Connection

  def start_link(opts) do
    GenServer.start_link __MODULE__, opts
  end

  def init(args) do
    {:ok, connection} = Connection.start_link(adapter: args[:adapter_interface])
    {:ok, %{connection: connection, adapter: args[:adapter_interface]}}
  end

  def handle_info({:text, message}, %{connection: connection} = state) do
    send connection, {:output, message}
    {:noreply, state}
  end
end
