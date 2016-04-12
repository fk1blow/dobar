defmodule Dobar.Conversation.Intention.Provider do
  alias Dobar.Conversation.Intention
  
  # TODO: hardcoded and should be done dinamically
  @intentions send_message: Intention.SendMessage

  def intention(name) when is_atom(name), do: @intentions[name]
  def intention(_) do
    raise "cannot provide an intention with an invalid name"
  end
  def intention do
    raise "cannot provide an intention with no name"
  end
end
