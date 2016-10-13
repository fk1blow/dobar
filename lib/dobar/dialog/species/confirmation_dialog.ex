defmodule Dobar.Dialog.ConfirmationDialog do
  use Dobar.Dialog.Species

  def handle_intent(%Intent{}, %{topic: nil, meta: nil, name: :root_dialog} = state) do
    GenEvent.notify(
      state.event_manager,
      %Reaction{about: :meta_as_root,
                text: "cannot start a dialog with a 'confirmation' command"})
    {:error, :meta_as_root}
  end

  def handle_intent(intent, state), do: super(intent, state)
end
