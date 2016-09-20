defmodule Dobar.Conversation.ReactionHandler do
  use GenEvent
  require Logger

  alias Dobar.Reaction, as: Reaction
  alias Dobar.Dialog.GenericDialog

  # events triggered for :dialog_events_manager, in response
  # to Dialog System reactions

  def handle_event(%Reaction{about: :question} = reaction, _) do
    Logger.info "text reaction - dialog question"
    Dobar.Interface.output(:text, reaction.text)
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :completed, data: data} = reaction, _) do
    Logger.info "dialog completed"
    Logger.info "completed features: #{inspect data.features}"
    Logger.info "completed intent: #{inspect data.intent}"
    Dobar.Responder.Supervisor.respond(String.to_atom(data.intent.name), data)
    Dobar.Interface.output(:text, reaction.text)
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :switch_conversation} = reaction, _) do
    intent = reaction.data.passthrough
    Logger.info "switch conversation"
    Logger.info "evaluate dialog for intent: #{intent.name}, confidence: #{intent.confidence}"
    case Process.whereis(:root_dialog) do
      nil ->
        dialog = Dobar.Dialog.Species.Routes.specie intent.name
        Logger.info "will evaluate dialog: #{inspect dialog}"
        {:ok, pid} = dialog.start_link(:root_dialog)
        GenericDialog.evaluate pid, intent
      pid ->
        GenericDialog.evaluate pid, intent
    end

    {:ok, nil}
  end

  def handle_event(%Reaction{about: :same_alternative_found} = reaction, _) do
    Logger.info "same alternative found for intent: #{inspect reaction.data.intent}"
    Dobar.Interface.output :text, "cannot start a dialog identical to the current one"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :purge_nomatches} = reaction, _) do
    Logger.info "cannot purge fields that don't match with parent's capabilities"
    Logger.info "purge nomatches intent: #{inspect reaction.data.intent.name}"
    Dobar.Interface.output :text, "cannot change the fields that dont' appear in the parent"
    Dobar.Interface.output :text, "continuing the dialog"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :intent_no_match} = reaction, _) do
    current_intent = reaction.data.dialog_intent.name
    input_intent = reaction.data.intent.name
    Logger.info "no topic match for intent: #{current_intent} and input intent: #{input_intent}"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :no_alternative_found} = reaction, _) do
    intent_name = reaction.data.intent.name
    Logger.info "no alternative found"
    Logger.info "current dialog intention: #{intent_name}"
    Dobar.Interface.output :text, "no alternative found for current intent #{inspect intent_name}"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :begin_topic} = reaction, _) do
    Logger.info "begin topic with intent: #{inspect reaction.data.intent}"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :alternative_reference_found} = reaction, _) do
    Logger.info "alternative reference dialog found for intent: #{inspect reaction.data.intent}"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :alternative_meta_found} = reaction, _) do
    Logger.info "alternative dialog found for intent: #{inspect reaction.data.intent}"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :continue_topic} = reaction, _) do
    Logger.info "continue topic with intent: #{inspect reaction.data.intent}"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :dialog_canceled} = reaction, _) do
    Logger.info "loggingreaction - dialog canceled"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :low_confidence_intent} = error, _) do
    Logger.info "errorreaction - low confidence intent"
    Logger.info "i'm do not know how to interpret that input"
    Logger.info "intent: #{inspect error.input_intent.name}"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :undefined_intention} = error, _state) do
    Logger.info "undefined intention has been evaluated"
    Dobar.Interface.output :text, "DoBar cannot respond to an undefined intention"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :meta_as_root} = error, _state) do
    Logger.info "errorreaction - cannot start a dialog with a meta intention"
    Dobar.Interface.output :text, error.text
    {:ok, nil}
  end

  def handle_event(_reaction, _state) do
    {:ok, nil}
  end
end
