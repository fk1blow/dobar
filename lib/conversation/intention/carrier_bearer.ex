defmodule Dobar.Conversation.Intention.CarrierBearer do
  use Dobar.Conversation.IntentionBehaviour

  intention :carrier_bearer do
    # cancel command not really used by this intention
    topic :cancel_command, reference: :cancel_command
  end
end
