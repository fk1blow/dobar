defmodule Dobar.Conversation.Topic do
  def start_topic(nil), do: {:ended, nil}
  def start_topic(slot), do: {:ok, slot}
end
