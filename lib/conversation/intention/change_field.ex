# TODO: this file should be moved outside the conversation realm
defmodule Dobar.Conversation.Intention.ChangeField do
  use Dobar.Conversation.IntentionBehaviour

  intention :change_field do
    relationship :meta
    topic :field_type, prio: 1, entity: "field_type"
    topic :field_value, prio: 2, entity: :input

    topic :cancel_command, reference: :cancel_command
  end
end
