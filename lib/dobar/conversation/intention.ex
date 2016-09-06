defmodule Dobar.Conversation.Intention do
  @moduledoc """
  Dobar Conversation Intention

  It manages the interface for the conversation intentions and their definitions
  and has the responsability to provide access to the definitions and proper
  initialization from the user.
  """

  use GenServer

  def start_link do
    IO.puts "...."
  end
end
