defmodule Dobar.Conversation.Intention.PurgeChangeFields do
  use Dobar.Conversation.IntentionBehaviour

  intention :purge_change_fields do
    topic :change_field, reference: :change_field
    topic :cancel_command, reference: :cancel_command
  end
end
