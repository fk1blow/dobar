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
      {:__block__, _, elements} ->
        Enum.map(elements, fn(topic) -> extract_topic.(elem topic, 2) end)
      {:topic, _, topic} ->
        [extract_topic.(topic)]
    end

    quote do
      @intentions Map.put(@intentions, unquote(name), unquote(topics))
    end
  end
end
