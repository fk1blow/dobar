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
      @ending_message "ok!"
      @before_compile Dobar.Conversation.Intention
    end
  end

  defmacro __before_compile__(_env) do
    alias Dobar.Model.Intent

    quote do
      def process_next(%Intent{} = intent) do
        next_topic(Enum.reverse(@topic_list), intent)
      end

      def process_expected(expected, old_intent, new_intent) do
        expected_topic(expected, old_intent, new_intent)
      end

      defp next_topic([], intent), do: {:ended, @ending_message, intent}
      defp next_topic([capability | tail], intent) do
        become_next = apply(capability.module, :become_next, [intent])
        case become_next do
          {:ok, reply} -> {:next, reply, capability}
          _ -> next_topic(tail, intent)
        end
      end

      defp expected_topic(%Capability{module: module}, old_intent, new_intent) do
        expected = apply(module, :handle_expected, [old_intent, new_intent])
        case expected do
          {:ok, intent} -> {:continue, intent}
          {:halt, reason} -> {:halt, reason}
        end
      end
    end
  end

  defmacro intention(name, do: block) do
    extract_topic = fn(topic) ->
      {hd(topic), Enum.flat_map(tl(topic), fn(x) -> x end)}
    end

    topics = case block do
      {:__block__, _, topics} ->
        Enum.map(topics, fn(topic) -> extract_topic.(elem topic, 2) end)
      {:topic, _, topic} ->
        [extract_topic.(topic)]
    end

    quote do
      @intentions Map.put @intentions, unquote(name), unquote(topics)
    end
  end
end
