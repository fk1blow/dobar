# TODO: this file and the capabilities should be moved outside the conversation realm
defmodule Dobar.Conversation.Intention.SendMessage do
  use Dobar.Conversation.Intention

  alias Dobar.Conversation.Intention

  # TODO: the `capability` macro needs another name
  capability :message_app, entity: "app_name", module: Intention.MessageApp
  capability :message_receiver, entity: "contact", module: Intention.MessageReceiver
  capability :message_body, entity: "fuckmeright", module: Intention.MessageBody
end
