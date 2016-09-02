defmodule Dobar.Dialog.InputHandler do
  require Logger
  use GenEvent

  alias Dobar.Model.Reaction.Logging, as: LoggingReaction
  alias Dobar.Model.Reaction.Text, as: TextReaction
  alias Dobar.Model.Reaction.Need, as: NeedReaction
  alias Dobar.Model.Reaction.Error, as: ErrorReaction

  def handle_event(%TextReaction{about: about} = reaction, _) do
    Logger.debug "received a reaction from the Dialog system"
    Logger.debug "topic_reaction: #{inspect reaction.topic_reaction}"
    {:ok, nil}
  end

  def handle_event(%ErrorReaction{} = error, _state) do
    Logger.debug "handler reaction to: #{inspect error.about}"
    Logger.debug "input intent: #{inspect error.input_intent}"
    {:ok, nil}
  end

  def handle_event(%LoggingReaction{} = reaction, _) do
    Logger.debug "input: reaction to: #{inspect reaction}"
    {:ok, nil}
  end

  def handle_event(_reaction, _state) do
    {:ok, nil}
  end
end
