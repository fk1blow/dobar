# TODO: must be renamed to InterfaceInputHandler
defmodule Dobar.Conversation.TextInputHandler do
  use GenEvent

  alias Dobar.Conversation.Intention.Evaluator

  def handle_event({:input, :text, input}, _) do
    task = Task.async(Evaluator, :evaluate_input, [{:text, input}])
    {:ok, intent} = Task.await(task)
    Dobar.Dialog.GenericDialog.evaluate :root_dialog, intent
    {:ok, nil}
  end
end
