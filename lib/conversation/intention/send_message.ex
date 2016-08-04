# TODO: this file should be moved outside the conversation realm
defmodule Dobar.Conversation.Intention.SendMessage do
  use Dobar.Conversation.IntentionBehaviour

  intention :send_message do
    topic :message_app, prio: 1, entity: [:application, :app, :app_name]
    topic :message_recipient, prio: 2, entity: [:contact, :receiver, :recipient]
    topic :message_body, prio: 3, entity: :input
    topic :approve, prio: 4, entity: [:confirm, :infirm]

    topic :change_field, reference: :change_field
    topic :cancel_command, reference: :cancel_command
  end
end
