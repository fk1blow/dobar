defmodule Dobar.Conversation.Intention.Provider do
  alias Dobar.Conversation.Intention

  @intentions send_message: Intention.SendMessage

  def intention(name) when is_atom(name), do: @intentions[name]

  def intention do
    raise "cannot provide an intention with no name"
  end
end
