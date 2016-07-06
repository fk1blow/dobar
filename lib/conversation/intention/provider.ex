# TODO: useless and fucked up module - refactor it!
defmodule Dobar.Conversation.Intention.Provider do
  alias Dobar.Conversation.Intention

  # TODO: hardcoded and should be done dinamically
  @intentions [
    send_message: Intention.SendMessage,
    change_recipient: Intention.SendMessage,
    cancel_command: Intention.CancelCommand
  ]

  def intention(name) when is_atom(name), do: {:ok, @intentions[name].intentions}
  def intention(_), do: {:error, "invalid intention name"}
  def intention, do: {:error, "cannot provide intention with no name"}
end
