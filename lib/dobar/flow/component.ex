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
  @callback execute() :: result()

  defmacro __using__(_opts) do
    quote do
      use GenServer

      @behaviour Dobar.Flow.Component

      @registry Dobar.Flow.Scheduler.Registry

      # api

      def start_link(node) do
        GenServer.start_link(__MODULE__, node,
          name: {:via, Registry, {Dobar.Flow.Scheduler.Registry, node.name}}
        )
      end

      @doc """
      Sends a message through the output port.

      This should call the connection actor which knows about the destination
      component/node
      """
      def send_to_output(_stuff) do
        #
      end

      # callbacks

      def init(node) do
        {:ok, %{node: node, status: :pristine}, {:continue, :am_i_root}}
      end

      def handle_continue(:am_i_root, state) do
        case state.node.is_root do
          true -> GenServer.cast(self(), :execute)
          _ -> nil
        end

        {:noreply, state}
      end

      def handle_cast(:execute, state) do
        execute()
        {:noreply, Map.put(state, :status, :inactive)}
      end
    end
  end
end
