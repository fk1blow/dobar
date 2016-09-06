# TODO: must be renamed to InterfaceInputHandler
defmodule Dobar.Conversation.TextInputHandler do
  use GenEvent

  alias Dobar.Conversation.Intention.Evaluator
  alias Dobar.Dialog.GenericDialog

  # handles events triggered by the Interface, as a side-effect of the user entering
  # some text in the prompt

  def handle_event({:input, :text, input}, _) do
    evaluator = Application.get_env(:dobar, Dobar.Conversation)
      |> Keyword.get(:evaluator)
      |> Keyword.get(:service)
    {:ok, intent} = Task.async(Evaluator, :evaluate, [{:text, input, evaluator}]) |> Task.await
    evaluate_dialog(intent)
    {:ok, nil}
  end

  defp evaluate_dialog(intent) do
    case Process.whereis(:root_dialog) do
      nil ->
        {:ok, pid} = GenericDialog.start_link(:root_dialog)
        GenericDialog.evaluate pid, intent
      pid ->
        GenericDialog.evaluate :root_dialog, intent
    end
  end
end
