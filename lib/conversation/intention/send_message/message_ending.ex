defmodule Dobar.Conversation.Intention.MessageEnding do
  @behaviour Dobar.Conversation.EndingBehaviour

  alias Dobar.Model.Intent

  def handle_ending(%Intent{} = intent) do
    {:ok, "woooooooooooooooooooo, this has ended clearly :d"}
  end
end
