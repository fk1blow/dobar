# TODO: must be renamed to InterfaceInputHandler
defmodule Dobar.Conversation.TextInputHandler do
  use GenEvent
  require Logger

  alias Dobar.Conversation.Intention.Evaluator
  alias Dobar.Dialog.GenericDialog

  # handles events triggered by the Interface, as a side-effect of the user entering
  # some text in the prompt

  def handle_event({:input, :text, input}, _) do
    Application.get_env(:dobar, Dobar.Conversation)
      |> Keyword.get(:evaluator)
      |> Keyword.get(:service)
      |> evaluate_input({:text, input})
      |> evaluate_dialog
    {:ok, nil}
  end

  defp evaluate_input(evaluator, {:text, input}) do
    Task.async(Evaluator, :evaluate, [{:text, input, evaluator}]) |> Task.await(10000)
  end

  defp evaluate_dialog({:error, reason}) do
    Logger.info "cannot evaluate text input because: #{reason}"
    Dobar.Interface.output :text, "cannot evaluate input; try again"
  end
  defp evaluate_dialog({:ok, intent}) do
    # Logger.info "evaluate dialog for intent: #{inspect intent}"
    case Process.whereis(:root_dialog) do
      nil ->
        {:ok, pid} = GenericDialog.start_link(:root_dialog)
        GenericDialog.evaluate pid, intent
      pid ->
        GenericDialog.evaluate pid, intent
    end
  end
end
