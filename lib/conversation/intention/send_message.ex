# TODO: this file and the capabilities should be moved outside the conversation realm
defmodule Dobar.Conversation.Intention.SendMessage do
  use Dobar.Conversation.Intention

  alias Dobar.Conversation.Intention

  # TODO: the `capability` macro needs another name
  # topic :message_app, entity: "app_name", module: Intention.MessageApp
  # topic :message_receiver, entity: "contact", module: Intention.MessageReceiver
  # topic :message_body, entity: "fuckmeright", module: Intention.MessageBody

  intention :send_message do
    topic :message_app, entity: "app_name"
    topic :message_recipient, entity: "contact"
    topic :message_body, field: "input"
  end

  IO.inspect @intentions
end
