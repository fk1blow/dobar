# TODO: move to Dobar.Dialog.Species.ChangeFieldDialog
defmodule Dobar.Dialog.ChangeFieldDialog do
  @moduledoc """
  This specialized dialog will handle "change_field" intents in a special way.
  Because change field relies mostly on the parent dialog, this specialized dialog
  will have to validate that...

  Note that it can have a "change_field" meta-dialog itself(alongside
  a "cancel_command" meta-dialog).
  """

  use Dobar.Dialog.Species

  alias Dobar.Reaction

  def handle_intent(intent, %{topic: nil, meta: nil, name: :root_dialog} = state) do
    GenEvent.notify(
      Dobar.DialogEvents,
      %Reaction{about: :meta_as_root,
                text: "cannot start a dialog with a 'change field' command",
                data: %{intent: intent}})
    {:error, :meta_as_root}
  end

  def handle_intent(intent, %{topic: nil, meta: nil, parent: parent} = state) do
    {:ok, topic} = Topic.start_link(intent)

    case Topic.forward(topic) do
      # %Reaction{type: :question} = reaction ->
      {:question, question} ->
          GenEvent.notify(Dobar.DialogEvents, %Reaction{about: :question, text: question})
        {:topic_output, %{topic: topic}}

      # %Reaction{type: :completed} = reaction ->
      {:completed, intent, features} ->
        GenEvent.notify(Dobar.DialogEvents, %Reaction{about: :completed, text: "ok"})
        # GenEvent.notify(Dobar.DialogEvents, %TextReaction{
        #   about: :completed, text: "ok", topic_reaction: reaction})
        unless root_dialog?(self) do
          # GenServer.cast parent, {:meta, reaction}
          GenServer.cast(parent,
            {:meta, %Dobar.Model.Meta{intent: intent, passthrough: state.passthrough}})
        end
        {:topic_end, :completed}
    end
  end

  def handle_intent(intent, state), do: super(intent, state)
end
