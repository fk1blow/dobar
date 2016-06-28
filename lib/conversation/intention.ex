defmodule Dobar.Conversation.Intention do
  @moduledoc """
  This is the protocol that basically defines an intention, which represents a
  preestablished command that dobar might understand.
  It usually consists of entities(frames, slots) that have to be completed
  in order to consider the intention resolved - user gets the command's answer.

  Its roles is to process the capabilities and respond accordingly when
  theres a need for the next dialog capability or the expected one.
  """

  alias Dobar.Conversation.Model.Capability

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
