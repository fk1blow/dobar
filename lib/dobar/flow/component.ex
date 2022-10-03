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

      # api

      def start_link(node) do
        GenServer.start_link(__MODULE__, [node_name: node.name],
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

      def init(node_name: name) do
        {:ok, %{name: name, status: :pristine}}
      end

      def handle_call(:execute, _from, state) do
        execute()
        {:reply, :ok, Map.put(state, :status, :inactive)}
      end
    end
  end
end
