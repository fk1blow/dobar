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
  end
  def intention(name), do: validate_intention(nil, name)

  defp validate_intention(nil, name),
    do: {:error, "cannot provide intention for name: #{inspect name}"}
  defp validate_intention(definition, _name), do: {:ok, definition}
end
