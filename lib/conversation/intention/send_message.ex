# TODO: this file and the capabilities should be moved outside the conversation realm
defmodule Dobar.Conversation.Intention.SendMessage do
  use Dobar.Conversation.Intention

  intention :edit_message do
    topic :message_recipient, entity: "contact"
  end

  intention :send_message do
    topic :message_app, entity: "app_name"
    topic :message_recipient, entity: "contact"
    topic :message_body, field: "input"
    # tbd...
    topic :change_recipient, intention: :change_recipient
  end

  IO.inspect @intentions
end
