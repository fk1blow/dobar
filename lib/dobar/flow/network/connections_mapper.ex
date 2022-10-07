defmodule Dobar.Flow.Network.ConnectionsMapper do
  @spec input_ports([{Connection.t(), pid()}]) :: Map.t()
  def input_ports(connections) when is_list(connections) do
    mapping =
      connections
      |> Enum.reduce(%{}, fn {conn, pid}, acc ->
        if Map.has_key?(acc, conn.to) do
          %{acc | conn.to => Map.put(acc[conn.to], conn.from, pid)}
        else
          Map.put(acc, conn.to, %{conn.from => pid})
        end
      end)

    mapping
  end

  @spec output_ports([{Connection.t(), pid()}]) :: Map.t()
  def output_ports(connections) when is_list(connections) do
    mapping =
      connections
      |> Enum.reduce(%{}, fn {conn, pid}, acc ->
        if Map.has_key?(acc, conn.from) do
          %{acc | conn.from => Map.put(acc[conn.from], conn.to, pid)}
        else
          Map.put(acc, conn.from, %{conn.to => pid})
        end
      end)

    mapping
  end
end
