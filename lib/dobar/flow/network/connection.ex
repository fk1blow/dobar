defmodule Dobar.Flow.Network.Connection do
  @moduledoc """
  Flow.Connection is the communication mechanism between Nodes
  """

  use GenServer

  def start_link(conn) do
    GenServer.start_link(__MODULE__, conn,
      name: {:via, Registry, {Dobar.Flow.Network.ConnectionsRegistry, conn.id}}
    )
  end

  @doc """
  Returns the last item in the message queue
  """
  def receive(server) do
    GenServer.call(server, :fetch)
  end

  @doc """
  Sends and :execute to the target node
  """
  def send(server, msg) do
    GenServer.cast(server, {:send, msg})
  end

  # Callbacks

  @impl true
  def init(connection) do
    {:ok, %{connection: connection, queue: []}}
  end

  @impl true
  def handle_call(:fetch, _from, state) do
    last_message = List.last(state.queue)

    updated_queue =
      case length(state.queue) do
        n when n > 1 -> Enum.drop(state.queue, -1)
        _ -> []
      end

    {:reply, last_message, %{state | queue: updated_queue}}
  end

  @impl true
  def handle_cast({:send, msg}, state) do
    case Registry.lookup(Dobar.Flow.Network.NodesRegistry, state.connection.to) do
      [{pid, _}] -> GenServer.cast(pid, :execute)
      _ -> nil
    end

    {:noreply, %{state | queue: [msg | state.queue]}}
  end
end
