defmodule Dobar.Conversation.IntentRouter do
  use Dobar.Conversation.Tree, includes: :cancel_action

  intention :send_message do
    capability :message_app, entity: [:app_name, :xrx]
    capability :message_receiver, entity: :contact
  end

  IO.inspect @intentions
end
