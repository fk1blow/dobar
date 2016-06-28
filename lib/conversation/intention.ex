defmodule Dobar.Conversation.Intention do
  defmacro __using__(_opts) do
    quote do
      import Dobar.Conversation.Intention
      @intentions Map.new
      @topic_list []
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
