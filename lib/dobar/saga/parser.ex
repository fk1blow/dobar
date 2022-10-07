defmodule Dobar.Saga.Parser do
  @moduledoc """
  Parses sagas from json input, validates them, etc
  """

  @type valid_saga :: {:ok, Dobar.Saga.t()}
  @type invalid_reason :: :empty_nodes | :empty_connections | :no_name
  @type invalid_saga ::
          {:error, invalid_reason()}
          | {:error, invalid_reason()}
          | {:error, invalid_reason()}

  @spec from_json(binary()) :: valid_saga() | invalid_saga()
  def from_json(json) when is_binary(json) do
    decoded_json = Jason.decode!(json)

    connections =
      decoded_json
      |> Map.get("connections")
      |> Enum.map(&Dobar.Saga.Connection.new/1)

    nodes =
      decoded_json
      |> Map.get("nodes")
      |> Enum.map(fn c -> Dobar.Saga.Node.new(c) end)

    version = decoded_json |> Map.get("version")

    name = decoded_json |> Map.get("name")

    saga = %Dobar.Saga{nodes: nodes, connections: connections, version: version, name: name}

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
      Map.get(saga, :name) == nil ->
        {:invalid, :no_name}

      Map.get(saga, :name) |> String.length() == 0 ->
        {:invalid, :no_name}

      Map.get(saga, :connections) |> Enum.count() == 0 ->
        {:invalid, :empty_connections}

      Map.get(saga, :nodes) |> Enum.count() == 0 ->
        {:invalid, :empty_nodes}

      true ->
        :valid
    end
  end
end
