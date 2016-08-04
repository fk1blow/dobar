defmodule Dobar.Conversation.Intention.EphemeralBearer do
  use Dobar.Conversation.IntentionBehaviour

  intention :ephemeral_bearer do
    # cancel command not really used by this intention
    topic :cancel_command, reference: :cancel_command
  end
end
