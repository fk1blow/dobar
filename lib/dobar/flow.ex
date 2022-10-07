defmodule Dobar.Flow do
  @moduledoc """
  Main entrypoint to the saga network
  Passing a json binary representation, it will try to parse then
  create a new network based on that
  """

  @spec from_json(binary()) :: any()
  def from_json(json) do
    case Dobar.Saga.Parser.from_json(json) do
      {:ok, saga} -> Dobar.Flow.Network.create_flow(Dobar.Flow.Network, saga)
      error -> error
    end
  end
end
