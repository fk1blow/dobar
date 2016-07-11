# TODO: this file should be moved outside the conversation realm
defmodule Dobar.Conversation.Intention.SendMessage do
  use Dobar.Conversation.IntentionBehaviour

  intention :change_recipient do
    # topic :confirmation, prio: 1, entity: "yes"
    topic :message_recipient, prio: 2, entity: "contact"
  end

  intention :send_message do
    topic :message_app, prio: 1, entity: "app_name"
    topic :message_recipient, prio: 2, entity: "contact"
    topic :message_body, prio: 3, key: "input", entity: nil
    # tbd...
    topic :change_recipient, intention: :change_recipient
  end

  IO.inspect @intentions
end
