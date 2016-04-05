defmodule Dobar.Conversation.IntentRouter do
  use Dobar.Conversation.Dialog, includes: :cancel_action

  alias Dobar.Conversation.Intention

  conversation :send_message, Intention.SendMessage do
    expect :message_app, entity: :app_name
    expect :message_receiver, entity: :contact
    expect :message_body, entity: :contact
  end

  IO.inspect @conversations
  IO.inspect @intention_module
end
