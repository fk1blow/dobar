defmodule Dobar.Dialog.ReactionsHandler do
  require Logger
  use GenEvent

  alias Dobar.Interface.Controller, as: Interface
  alias Dobar.Model.Reaction.Text, as: TextReaction
  alias Dobar.Model.Reaction.Need, as: NeedReaction
  alias Dobar.Model.Reaction.Error, as: ErrorReaction

  def handle_event(%TextReaction{about: about} = reaction, _) do
    Interface.send_output {:text, "should send data to the ouput, represented by the interface controller"}
    {:ok, nil}
  end

  def handle_event(%NeedReaction{} = reaction, _) do
    Logger.info "DoBar needs something - add description of the need reaction"
    {:ok, nil}
  end

  def handle_event(%ErrorReaction{about: :low_confidence_intent} = error, _) do
    Logger.info "i'm do not know how to interpret that input"
    Logger.info "intent: #{inspect error.input_intent.name}"
    {:ok, nil}
  end

  def handle_event(%ErrorReaction{about: :undefined_intention} = error, _state) do
    Interface.send_output {:text, "cannot react because i'm unable to handle undefined intention"}
    {:ok, nil}
  end

  def handle_event(_reaction, _state) do
    {:ok, nil}
  end
end
