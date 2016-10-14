defmodule Dobar.Conversation.Definition do
  defmacro __using__(_opts) do
    quote do
      import Dobar.Conversation.Definition

      @default_intentions %{carrier_bearer: [meta: []]}
      @intentions Map.merge(%{}, @default_intentions)
      @before_compile Dobar.Conversation.Definition
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def intention(name) when is_atom(name) do
        intention_definitions[name]
        |> validate_intention(name)
        |> normalize_structure(name)
      end
      def intention(name), do: validate_intention(nil, name)

      defp intention_definitions, do: @intentions

      defp validate_intention(nil, key_name),
        do: {:nodefinition, "intention not defined for key name: #{inspect key_name}"}
      defp validate_intention(definition, _key_name), do: {:ok, definition}

      defp normalize_structure({:nodefinition, reason}, _key_name),
        do: {:nodefinition, reason}
      defp normalize_structure({:ok, definition}, key_name) do
        {:ok, Map.put(%{}, key_name, definition)}
      end
    end
  end

  defmacro intention(name) do
    quote do
      @intentions Map.put(@intentions, unquote(name), [])
    end
  end

  defmacro intention(name, do: block) do
    extract_topic = fn(topic) ->
      {hd(topic), Enum.flat_map(tl(topic), fn(x) -> x end)}
    end

    topics = case block do
      {:topic, _, topic} ->
        [extract_topic.(topic)]

      {:relationship, _, relation} ->
        [extract_topic.(relation)]

      {:__block__, _, elements} ->
        definition =
          elements
          |> Enum.filter(&(elem(&1, 0) != :relationship))
          |> Enum.map(fn(topic) -> extract_topic.(elem topic, 2) end)

        # find a :relationship key and filter it out
        relationship =
          elements
          |> Enum.filter(&(elem(&1, 0) == :relationship))
          |> Enum.flat_map(&(elem &1, 2))

        # if the relationship exists, inject it inside the definition
        case relationship do
          [h|_] -> Keyword.put definition, :relationship, h
          _     -> definition
        end
    end

    quote do
      @intentions Map.put(@intentions, unquote(name), unquote(topics))
    end
  end
end
