defmodule Dobar.Conversation.ReactionHandler do
  use GenEvent
  require Logger

  alias Dobar.Model.Reaction.Text, as: TextReaction
  alias Dobar.Model.Reaction.Error, as: ErrorReaction
  alias Dobar.Model.Reaction.Need, as: NeedReaction

  # events triggered by the Conversation as :dialog_events_manager, in response
  # to Dialog System reactions

  def handle_event(%TextReaction{about: about} = reaction, _) do
    IO.puts "text reaction: #{inspect reaction}"
    msg = "should send data to the ouput, represented by the interface controller"
    Dobar.Interface.output(:text, msg)
    {:ok, nil}
  end

  def handle_event(%ErrorReaction{about: :low_confidence_intent} = error, _) do
    Logger.info "i'm do not know how to interpret that input"
    Logger.info "intent: #{inspect error.input_intent.name}"
    {:ok, nil}
  end

  def handle_event(%ErrorReaction{about: :undefined_intention} = error, _state) do
    Logger.info "undefined intention has been reached"
    # bla-bla send {:text, "cannot react because i'm unable to handle undefined intention"}
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
