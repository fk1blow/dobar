defmodule Dobar.Conversation.Topic do
  alias Dobar.Model.Intent

  def should_become_next(%Intent{} = old_intent, %Intent{} = new_intent) do
    IO.puts "should become next:"
    IO.puts "old_intent: #{inspect old_intent}"
    IO.puts "and new_intent: #{inspect new_intent}"
  end

  @doc """
  Actually, the topic will receive
  """
  def handle_expected_(%Intent{} = old_intent, %Intent{} = new_intent) do
    IO.puts "should handle the expected topic"
  end
end
