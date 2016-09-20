defmodule Dobar.Xapp.AnotherGenericResponder do
  use Dobar.Responder

  on :send_message, data: %{features: features} do
    recipient = features.message_recipient.value
    message = "pffff, never gonna give... the message back to #{recipient}"
    reply(interface, {:text, message})
  end
end
