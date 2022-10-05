defmodule Dobar.Saga.Parser do
  @moduledoc """
  Parses sagas from json input, validates them, etc
  """

  @type valid_saga :: {:ok, Dobar.Saga.t()}
  @type invalid_saga :: {:invalid, :nodes} | {:invalid, :connections}

  @spec from_json(binary()) :: valid_saga() | invalid_saga()
  def from_json(json) when is_binary(json) do
    saga = Dobar.Saga.new(Jason.decode!(json))

    case validate_saga(saga) do
      :valid -> {:ok, saga}
      {:invalid, reason} -> {:error, reason}
    end
  end

  def from_json(_) do
    {:error, :invalid}
  end

  defp validate_saga(saga) do
    cond do
      Enum.count(Map.get(saga, :connections)) == 0 ->
        {:invalid, :connections}

      Enum.count(Map.get(saga, :nodes)) == 0 ->
        {:invalid, :nodes}

      true ->
        :valid
    end
  end
end
