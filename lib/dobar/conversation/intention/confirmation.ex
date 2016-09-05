# TODO: this file should be moved outside the conversation realm
defmodule Dobar.Conversation.Intention.Confirmation do
  use Dobar.Conversation.Intention.Definition

  intention :confirmation do
    relationship :meta
    topic :approve, entity: [:confirm, :infirm]
    topic :cancel_command, reference: :cancel_command
  end
end
