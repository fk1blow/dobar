defmodule Dobar.Conversation.TextInputHandler do
  use GenEvent

  def handle_event({:input, :text, input}, _) do
    IO.puts "event inside TextInputHandler: #{inspect input}"
    {:ok, nil}
  end
end
