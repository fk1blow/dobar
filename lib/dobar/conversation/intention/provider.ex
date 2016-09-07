defmodule Dobar.Conversation.Intention.Provider do
  @moduledoc """
  Conversation Intention Provider

  Provides a store for the intention definitions alongside an interface
  for fetching them.
  """

  def start_link(opts) do
    Agent.start_link(fn -> opts[:definitions] || Map.new end, name: __MODULE__)
  end

  def intention(name) when is_atom(name) do
    Agent.get(__MODULE__, fn definitions -> definitions[name] end)
    |> validate_intention(name)
    |> normalize_structure(name)
  end
  def intention(name), do: validate_intention(nil, name)

  defp validate_intention(nil, key_name),
    do: {:error, "cannot provide intention for key name: #{inspect key_name}"}
  defp validate_intention(definition, _key_name), do: {:ok, definition}

  defp normalize_structure({:error, reason}, _key_name), do: {:error, reason}
  defp normalize_structure({:ok, definition}, key_name) do
    {:ok, Map.put(%{}, key_name, definition)}
  end
end
