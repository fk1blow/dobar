defmodule Dobar.Flow.Port do
  use GenServer

  # def start(args) do
  #   GenServer.start(__MODULE__, [args])
  # end

  def init(args) do
    {:ok, args}
  end

  @moduledoc """
  Ports are the points of contact between processes and connections
  """

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
