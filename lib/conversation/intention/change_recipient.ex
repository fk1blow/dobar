# TODO: this file should be moved outside the conversation realm
defmodule Dobar.Conversation.Intention.ChangeRecipient do
  use Dobar.Conversation.IntentionBehaviour

  intention :change_recipient do
    relationship :meta
    topic :message_recipient, prio: 2, entity: "contact"
  end


  IO.inspect @intentions
end
