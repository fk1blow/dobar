defmodule Dobar.Conversation.Intention.MessageEnding do
  @behaviour Dobar.Conversation.EndingBehaviour

  @next_reply "what's the application you would like to use?"
  @halt_reason "cannot find the application name in the provided reply!"

  alias Dobar.Model.Intent

  def handle_ending(%Intent{} = intent) do
    {:ok, "woooooooooooooooooooo, this has ended clearly :d"}
  end
end
