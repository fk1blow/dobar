# TODO: rename it do `Dobar.Conversation.Intention.IntentionBehaviour
defmodule Dobar.Conversation.IntentionBehaviour do
  defmacro __using__(_opts) do
    quote do
      import Dobar.Conversation.IntentionBehaviour
      @intentions Map.new
      @topic_list []

      @before_compile Dobar.Conversation.IntentionBehaviour
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def intentions, do: @intentions
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
        definition = elements
        |> Enum.filter(&(elem(&1, 0) != :relationship))
        |> Enum.map(fn(topic) -> extract_topic.(elem topic, 2) end)
        # find a :relationship key and filter it out
        relationship = elements
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
