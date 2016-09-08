defmodule Dobar.Conversation.ReactionHandler do
  use GenEvent
  require Logger

  alias Dobar.Model.Reaction.Text, as: TextReaction
  alias Dobar.Model.Reaction.Error, as: ErrorReaction
  alias Dobar.Model.Reaction.Need, as: NeedReaction
  alias Dobar.Model.Reaction.Passthrough, as: PassthroughReaction
  alias Dobar.Dialog.GenericDialog

  # events triggered for :dialog_events_manager, in response
  # to Dialog System reactions

  def handle_event(%TextReaction{about: :question} = reaction, _) do
    message = reaction.topic_reaction.features.question
    Dobar.Interface.output(:text, message)
    {:ok, nil}
  end

  def handle_event(%TextReaction{about: :completed} = reaction, _) do
    features = reaction.topic_reaction.features
    case features do
      [h|t] ->
        Logger.info "text reaction - dialog completed, reaction: #{inspect reaction}"
        Dobar.Interface.output(:text, reaction.text)
      %{question: question} ->
        Dobar.Interface.output :text, question
    end
    {:ok, nil}
  end

  def handle_event(%PassthroughReaction{about: :switch_conversation, intent: intent} = reaction, _) do
    Logger.info "evaluate dialog for intent: #{intent.name}, confidence: #{intent.confidence}"

    case Process.whereis(:root_dialog) do
      nil ->
        # Not shure if the version below works better; for future bugs that
        # may appear, comment the old logic and keep it here
        # {:ok, pid} = GenericDialog.start_link(:root_dialog)
        # GenericDialog.evaluate pid, intent

        dialog = Dobar.Dialog.Species.Routes.specie intent.name
        Logger.info "will evaluate dialog: #{inspect dialog}"

        {:ok, pid} = dialog.start_link(:root_dialog)
        GenericDialog.evaluate pid, intent
      pid ->
        GenericDialog.evaluate pid, intent
    end

    {:ok, nil}
  end

  def handle_event(%ErrorReaction{about: :low_confidence_intent} = error, _) do
    Logger.info "i'm do not know how to interpret that input"
    Logger.info "intent: #{inspect error.input_intent.name}"
    {:ok, nil}
  end

  def handle_event(%ErrorReaction{about: :undefined_intention} = error, _state) do
    Logger.info "undefined intention has been evaluated"
    Dobar.Interface.output :text, "DoBar cannot respond to an undefined intention"
    {:ok, nil}
  end

  def handle_event(%ErrorReaction{about: :meta_as_root} = error, _state) do
    Logger.info "cannot start a dialog with a meta intention"
    Dobar.Interface.output :text, error.text
    {:ok, nil}
  end

  def handle_event(%NeedReaction{} = reaction, _) do
    Logger.info "DoBar needs something - add description of the need reaction"
    {:ok, nil}
  end

  def handle_event(_reaction, _state) do
    {:ok, nil}
  end
end
