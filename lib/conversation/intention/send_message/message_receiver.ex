defmodule Dobar.Conversation.Intention.MessageReceiver do
  @behaviour Dobar.Conversation.Intention.Capability

  @next_reply "what's the application you would like to use?"
  @halt_reply "cannot find the application name in the provided reply!"

  alias Dobar.Model.Intent
end
