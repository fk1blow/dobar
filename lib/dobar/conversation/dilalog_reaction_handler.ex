defmodule Dobar.Conversation.ReactionHandler do
  use GenEvent
  require Logger

  alias Dobar.Reaction.Question, as: QuestionReaction
  alias Dobar.Reaction, as: Reaction

  alias Dobar.Reaction.Text, as: TextReaction
  alias Dobar.Reaction.Error, as: ErrorReaction
  alias Dobar.Reaction.Need, as: NeedReaction
  alias Dobar.Reaction.Passthrough, as: PassthroughReaction
  alias Dobar.Reaction.Logging, as: LoggingReaction
  alias Dobar.Dialog.GenericDialog

  # events triggered for :dialog_events_manager, in response
  # to Dialog System reactions

  def handle_event(%Reaction{about: :question} = reaction, _) do
    Logger.info "text reaction - dialog question"
    message = reaction.text
    Dobar.Interface.output(:text, message)
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :completed, data: data} = reaction, _) do
    Logger.info "text reaction - dialog completed"
    features = data.features
    # case features do
    #   [h|t] ->
        # Logger.info "completed reaction data: #{inspect data.features}, and intent: #{inspect data.intent}"
        Logger.info "completed features: #{inspect data.features}, and intent: #{inspect data.intent.name}"
        Dobar.Interface.output(:text, reaction.text)
      # shouldn't this be a {:statement, statement} instead of :question?
      # %{question: question} ->
      #   Dobar.Interface.output :text, question
    # end
    {:ok, nil}
  end

  def handle_event(%PassthroughReaction{about: :switch_conversation, intent: intent} = reaction, _) do
    Logger.info "passthroughreaction - switch conversation"
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

  def handle_event(%TextReaction{about: :no_alternative_found} = reaction, _) do
    intent_name = reaction.topic_reaction.intent.name
    Logger.info "textreaction - no alternative found"
    Logger.info "current dialog intention: #{intent_name}"
    Dobar.Interface.output :text, "no alternative found for current intent #{inspect intent_name}"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :intent_no_match} = reaction, _) do
    IO.puts "loggingreaction - intent no match; to be outputted to the interface"
    {:ok, nil}
  end

  def handle_event(%Reaction{about: :begin_topic} = reaction, _) do
    Logger.info "begin topic with intent: #{inspect reaction.data.intent}"
    {:ok, nil}
  end

  def handle_event(%LoggingReaction{about: :alternative_reference_found} = reaction, _) do
    Logger.info "alternative_reference_found"
    {:ok, nil}
  end

  def handle_event(%LoggingReaction{about: :alternative_meta_found} = reaction, _) do
    Logger.info "alternative_meta_found"
    {:ok, nil}
  end

  def handle_event(%LoggingReaction{about: :continue_topic} = reaction, _) do
    Logger.info "continue topic with intent: #{inspect reaction.data.intent}"
    {:ok, nil}
  end

  def handle_event(%LoggingReaction{about: :dialog_canceled} = reaction, _) do
    Logger.info "loggingreaction - dialog canceled"
    # Logger.info "cancelling dialog: #{reaction.topic_reaction.intent.name}"
    {:ok, nil}
  end

  def handle_event(%ErrorReaction{about: :low_confidence_intent} = error, _) do
    Logger.info "errorreaction - low confidence intent"
    Logger.info "i'm do not know how to interpret that input"
    Logger.info "intent: #{inspect error.input_intent.name}"
    {:ok, nil}
  end

  # def handle_event(%Reaction{about: :undefined_intention} = error, _state) do
  #   Logger.info "errorreaction - undefined intention has been evaluated"
  #   Dobar.Interface.output :text, "DoBar cannot respond to an undefined intention"
  #   {:ok, nil}
  # end

  def handle_event(%ErrorReaction{about: :meta_as_root} = error, _state) do
    Logger.info "errorreaction - cannot start a dialog with a meta intention"
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
