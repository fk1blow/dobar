# TODO: this file should be moved outside the conversation realm
defmodule Dobar.Conversation.Intention.ChangeRecipient do
  use Dobar.Conversation.IntentionBehaviour

  intention :cancel_command do
    topic :confirmation, entity: "yes"
  end
end
