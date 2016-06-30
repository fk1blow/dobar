# TODO: this file should be moved outside the conversation realm
defmodule Dobar.Conversation.Intention.CancelCommand do
  use Dobar.Conversation.IntentionBehaviour

  intention :cancel_command do
    topic :confirmation, entity: "yes"
  end

  IO.inspect @intentions
end
