defmodule Dobar.Flow do
  @moduledoc """
  Main entrypoint to the saga network
  Passing a json binary representation, it will try to parse then
  create a new network based on that
  """

  @spec from_json(binary()) :: term()
  def from_json(json) do
    case Dobar.Saga.Parser.from_json(json) do
      {:ok, saga} -> IO.inspect(saga)
      {:error, reason} -> IO.inspect(reason)
    end
  end
end
