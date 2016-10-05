defmodule Dobar.Xapp.AnotherGenericResponder do
  use Dobar.Responder

  alias Dobar.Reaction

  on %Reaction{about: :completed, trigger: %{name: "send_message"}, features: features} do
    recipient = features.message_recipient.value
    message = "pffff, never gonna give... the message back to #{recipient}"
    reply(interface, {:text, message})
  end
end
