defmodule Dobar.Dialog.ReactionsHandler do
  use GenEvent

  alias Dobar.Interface.Controller, as: Interface
  alias Dobar.Model.Reaction.Text, as: TextReaction
  alias Dobar.Model.Reaction.Need, as: NeedReaction
  alias Dobar.Model.Reaction.Error, as: ErrorReaction

  def handle_event(%TextReaction{} = reaction, _) do
    IO.puts "received a reaction from the Dialog system: #{inspect reaction.text}"
    {:ok, nil}
  end

  def handle_event(%NeedReaction{} = reaction, _) do
    IO.puts "DoBar needs something - add description of the need reaction"
    {:ok, nil}
  end

  def handle_event(%ErrorReaction{text: :low_confidence_intent} = error, _) do
    IO.puts "i'm do not know how to interpret that input"
    IO.puts "intent: #{insect error.reaction.intent}"
    IO.puts "_______________________________________"
    {:ok, nil}
  end

  def handle_event(%ErrorReaction{text: :undefined_intention} = error, _state) do
    IO.puts "cannot react because i'm unable to handle undefined intention"
    IO.puts "intent: #{insect error.reaction.intent}"
    IO.puts "_______________________________________"
    {:ok, nil}
  end
end
