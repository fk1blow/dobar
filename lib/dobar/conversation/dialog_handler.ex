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

  def handle_event(%Reaction{about: :question} = reaction, state) do
    send(state.conversation, {:dialog_reaction, reaction})
    {:ok, state}
  end

  # def handle_event(%Reaction{about: :canceled} = reaction, state) do
  #   send(state.conversation, {:dialog_reaction, reaction})
  #   {:ok, state}
  # end

  # def handle_event(%Reaction{about: :intent_no_match} = reaction, state) do
  #   send(state.conversation, {:dialog_reaction, reaction})
  #   {:ok, state}
  # end

  # def handle_event(%Reaction{about: :no_alternative_found} = reaction, state) do
  #   send(state.conversation, {:dialog_reaction, reaction})
  #   {:ok, state}
  # end

  # def handle_event(%Reaction{about: :low_confidence_intent} = reaction, state) do
  #   send(state.conversation, {:dialog_reaction, reaction})
  #   {:ok, state}
  # end

  # def handle_event(%Reaction{about: :undefined_intention} = reaction, state) do
  #   send(state.conversation, {:dialog_reaction, reaction})
  #   {:ok, state}
  # end

  # def handle_event(%Reaction{about: :meta_as_root} = reaction, state) do
  #   send(state.conversation, {:dialog_reaction, reaction})
  #   {:ok, state}
  # end

  def handle_event(%Reaction{about: :switch_conversation, trigger: trigger} = reaction, state) do
    send(state.conversation, {:switch_dialog, reaction})
    {:ok, state}
  end

  def handle_event(_, state) do
    {:ok, state}
  end
end
