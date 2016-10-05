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
      state.event_manager,
      %Reaction{about: :meta_as_root,
                text: "cannot start a dialog with a 'change field' command",
                trigger: intent})
    {:error, :meta_as_root}
  end

  def handle_intent(intent, %{topic: nil, meta: nil, parent: parent} = state) do
    {:ok, topic} = Topic.start_link(intent, [definitions: state.definitions])

    case Topic.forward(topic) do
      {:question, question} ->
          GenEvent.notify(state.event_manager, %Reaction{about: :question, text: question})
        {:topic_output, %{topic: topic}}

      {:completed, intent, _features} ->
        GenEvent.notify(state.event_manager, %Reaction{about: :completed, text: "ok"})
        unless root_dialog?(self) do
          GenServer.cast(parent,
            {:meta, %Dobar.Model.Meta{intent: intent, passthrough: state.passthrough}})
        end
        {:topic_end, :completed}
    end
  end

  def handle_intent(intent, state), do: super(intent, state)
end
