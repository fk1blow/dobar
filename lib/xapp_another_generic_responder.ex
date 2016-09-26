defmodule Dobar.Xapp.AnotherGenericResponder do
  use Dobar.Responder

  alias Dobar.Responder.Response

  # on :send_message, data: %{features: features} do
  #   recipient = features.message_recipient.value
  #   message = "pffff, never gonna give... the message back to #{recipient}"
  #   reply(interface, {:text, message})
  # end

  # on :say_some, _ do
  # on %{about: :send_message, data: data} do
  #   IO.puts "xxx2 on generic responder, data: #{inspect data}"
  # end

  hear ~r"kaboom" do
    IO.puts "dobar heared this type of message from the user so you can..."
  end

  respond topic: :time do
    IO.puts "dobar just asked you about this topic - `:time`"
  end

  react :dialog_cancel, data: %{} do
    IO.puts "dobar has canceled the dialog so you can to whatever you want"
  end
end
