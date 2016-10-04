defmodule Dobar.Conversation.LoggingHandler do
  use GenEvent
  require Logger

  alias Dobar.Reaction
  alias Dobar.Dialog.GenericDialog

  def handle_event(%Reaction{about: :question} = reaction, state) do
    Logger.info "text reaction - dialog question"
    {:ok, state}
  end

  def handle_event(%Reaction{about: :completed} = reaction, state) do
    Logger.info "dialog completed"
    Logger.info "completed features: #{inspect reaction.features}"
    Logger.info "completed intent: #{inspect reaction.trigger}"
    {:ok, state}
  end

  def handle_event(%Reaction{about: :same_alternative_found} = reaction, _) do
    Logger.info "same alternative found for intent: #{inspect reaction.trigger}"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :purge_nomatches} = reaction, _) do
    Logger.info "cannot purge fields that don't match with parent's capabilities"
    Logger.info "purge nomatches intent: #{inspect reaction.trigger.name}"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :intent_no_match} = reaction, _) do
    current_intent = reaction.other.dialog_intent.name
    input_intent = reaction.trigger.name
    Logger.info "no topic match for intent: #{current_intent} and input intent: #{input_intent}"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :no_alternative_found} = reaction, _) do
    intent_name = reaction.trigger.name
    Logger.info "no alternative found"
    Logger.info "current dialog intention: #{intent_name}"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :begin_topic} = reaction, state) do
    Logger.info "begin topic with intent: #{inspect reaction.trigger}"
    {:ok, state}
  end

  def handle_event(%Reaction{about: :alternative_reference_found} = reaction, _) do
    Logger.info "alternative reference dialog found for intent: #{inspect reaction.trigger}"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :alternative_meta_found} = reaction, _) do
    Logger.info "alternative dialog found for intent: #{inspect reaction.trigger}"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :continue_topic} = reaction, _) do
    Logger.info "continue topic with intent: #{inspect reaction.trigger}"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :canceled} = reaction, _) do
    Logger.info "dialog canceled"
    Logger.info "canceled intent: #{inspect reaction.trigger.name}"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :low_confidence_intent} = reaction, _) do
    Logger.info "errorreaction - low confidence intent"
    Logger.info "i'm do not know how to interpret input for intent"
    Logger.info "TODO# reaction: #{inspect reaction}"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :undefined_intention} = error, _state) do
    Logger.info "undefined intention has been evaluated"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :meta_as_root} = reaction, _state) do
    Logger.info ":meta_as_root"
    Logger.info reaction.text
    {:ok, nil}
  end

  def handle_event(_reaction, _state) do
    {:ok, nil}
  end
end
