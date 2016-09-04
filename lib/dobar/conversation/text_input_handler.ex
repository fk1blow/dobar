defmodule Dobar.Conversation.TextInputHandler do
  use GenEvent

  def handle_event({:input, :text, input}, _) do
    Dobar.Conversation.Intention.evaluate_intent :text, input
    {:ok, nil}
  end
end
