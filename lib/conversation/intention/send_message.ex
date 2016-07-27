# TODO: this file should be moved outside the conversation realm
defmodule Dobar.Conversation.Intention.SendMessage do
  use Dobar.Conversation.IntentionBehaviour

  intention :send_message do
    topic :message_app, prio: 1, entity: "app_name"
    topic :message_recipient, prio: 2, entity: [:contact, :receiver, :recipient]
    topic :message_body, prio: 3, entity: :input

    # topic :change_recipient, reference: :change_recipient
    topic :change_field, reference: :change_field
    # cancel_command must be injected automagically for each command except itself
    topic :cancel_command, reference: :cancel_command
  end

  IO.inspect @intentions
end
