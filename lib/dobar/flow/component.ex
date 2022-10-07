defmodule Dobar.Flow.Component do
  @moduledoc """
  A component is the logic of a process.
  """

  @type error_reason :: term()

  @type next_node :: term()

  @type result :: {:ok, next_node} | {:error, error_reason}

  # the status of a running components process
  # note that the termination is not really there yet
  @type status :: :pristine | :active | :inactive

  @doc """
  execute a component inside a process
  it also changes is status from :pristine to :active
  """
  @callback execute(term()) :: result()

  defmacro __using__(_opts) do
    quote do
      use GenServer

      alias Dobar.Flow.Network.{Node}

      @behaviour Dobar.Flow.Component

      @registry Dobar.Flow.Network.NodesRegistry

      @type node_state :: %{node: Node.t(), status: atom()}

      # api

      def start_link([node: node] = args) do
        # IO.inspect(node.id)

        GenServer.start_link(__MODULE__, args,
          name: {:via, Registry, {Dobar.Flow.Network.NodesRegistry, node.id}}
        )
      end

      @doc """
      Sends a message through the output port.

      This should call the connection actor which knows about the destination
      component/node
      """
      # @spec send_to_output(term(), node_state()) :: any()
      def send_to_output(to_port, msg, state) do
        destination_port = Map.get(state.node.ports, to_port)
        [{pid, _}] = Registry.lookup(Dobar.Flow.Network.ConnectionsRegistry, destination_port)
        Dobar.Flow.Network.Connection.send(pid, msg)
      end

      def fetch_from_input(from_port, state) do
        destination_port = Map.get(state.node.ports, from_port)
        [{pid, _}] = Registry.lookup(Dobar.Flow.Network.ConnectionsRegistry, destination_port)
        Dobar.Flow.Network.Connection.receive(pid)
      end

      # callbacks

      @typep init_args :: [node: Node.t()]

      @impl true
      @spec init(init_args()) :: {:ok, node_state(), {:continue, term()}}
      def init(node: node) do
        {:ok, %{node: node, status: :pristine}}
      end


      @impl true
      def handle_cast(:execute, state) do
        {:ok, status} = execute(state)
        {:noreply, Map.put(state, :status, status)}
      end
    end
  end
end
