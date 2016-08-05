defmodule Dobar.Conversation.Intention.CarrierBearer do
  use Dobar.Conversation.IntentionBehaviour

  intention :carrier_bearer do
    relationship :meta
  end
end
