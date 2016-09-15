defmodule Dobar.Conversation.TimelineHandler do
  use GenEvent
  require Logger

def handle_event(_message, _state) do
  # IO.puts "should start handling reactions and put it on the timeline"
  {:ok, nil}
  end
end
