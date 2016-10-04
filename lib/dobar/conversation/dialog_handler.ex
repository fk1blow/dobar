defmodule Dobar.Conversation.DialogHandler do
  use GenEvent
  require Logger

  alias Dobar.Reaction
  alias Dobar.Dialog.GenericDialog

  def init(args) do
    case args[:conversation] do
      name when is_atom(name) or is_pid(name) -> {:ok, %{conversation: name}}
      _ -> {:error, "cannot start dialog handler without callback module"}
    end
  end

  def handle_event(%Reaction{about: :completed} = reaction, state) do
    send(state.conversation, {:dialog_reaction, reaction})
    {:ok, state}
  end

  def handle_event(%Reaction{about: :switch_conversation} = reaction, state) do
    send(state.conversation, {:swith_conversation, reaction})
    {:ok, state}
  end

  # on canceled, you just send a message to the conversation. With this, the conversation
  # will attempt to recreate the dialog pid and replace the old one

  def handle_event(_, state) do
    {:ok, state}
  end
end
