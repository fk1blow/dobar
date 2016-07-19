# TODO: this file should be moved outside the conversation realm
defmodule Dobar.Conversation.Intention.CancelCommand do
  use Dobar.Conversation.IntentionBehaviour

  # TODO: can add a meta key that signals the "relationship" that it has with
  # other intentions, eg: it doesn't react "well"(define what "well" means) when
  # combining with itself(meta-intention of itself)

  intention :cancel_command do
    relationship :meta
    # topic :confirmation, entity: "yes"
    topic :approve, entity: {:confirm, :infirm}
  end
end
