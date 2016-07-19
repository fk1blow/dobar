# TODO: this file should be moved outside the conversation realm
defmodule Dobar.Conversation.Intention.Confirmation do
  use Dobar.Conversation.IntentionBehaviour

  intention :confirmation do
    relationship :meta
    topic :approve, entity: [:confirm, :infirm]
  end
end
