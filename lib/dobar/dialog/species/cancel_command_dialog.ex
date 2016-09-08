defmodule Dobar.Dialog.CancelCommandDialog do
  use Dobar.Dialog.Species

  def handle_intent(%Intent{} = intent, %{topic: nil, meta: nil, name: :root_dialog} = state) do
    GenEvent.notify(
      Dobar.DialogEvents,
      %ErrorReaction{about: :meta_as_root,
                     text: "cannot start a dialog with a 'cancel' command",
                     input_intent: intent})
    {:error, :meta_as_root}
  end

  def handle_intent(intent, state), do: super(intent, state)
end
