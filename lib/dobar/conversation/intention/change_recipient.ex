# DEPRECATED in favour of `ChangeField`
# TODO: this file should be moved outside the conversation realm
defmodule Dobar.Conversation.Intention.ChangeRecipient do
  use Dobar.Conversation.Intention.Definition

  intention :change_recipient do
    relationship :meta
    topic :message_recipient, prio: 2, entity: "contact"
    topic :cancel_command, reference: :cancel_command
  end


  IO.inspect @intentions
end
