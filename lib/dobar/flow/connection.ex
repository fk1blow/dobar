defmodule Dobar.Flow.Connection do
  @moduledoc """
  Flow.Connection is the communication mechanism between Nodes
  """

  use GenServer

  # def start(args) do
  #   GenServer.start(__MODULE__, [args])
  # end

  def init(args) do
    {:ok, args}
  end

  @doc """
  Reads the IN port's (incoming) packets
  """
  def receive do
    #
  end

  @doc """
  Sends a packet to the OUT port
  """
  def send do
    #
  end
end
