# TODO: useless and fucked up module - refactor it!
defmodule Dobar.Conversation.Intention.Provider do
  alias Dobar.Conversation.Intention
  alias Dobar.Model.Intent

  # TODO: hardcoded and should be done dinamically
  @intentions [
    send_message: Intention.SendMessage,
    cancel_command: Intention.CancelCommand
  ]

  @metaintentions [
    change_recipient: Intention.SendMessage,
  ]

  def normal_intention(name), do: intention(@intentions, name)
  def meta_intention(name), do: intention(@metaintentions, name)

  # TODO: this function should be renamed
  def alternate(%Intent{confidence: confidence, name: intent_name} = intent) do
    IO.puts "intent_name: #{inspect intent_name}"
    IO.inspect Intention.SendMessage.intentions
    cond do
      confidence > 0.8 -> intention(String.to_atom(intent_name))
      true             -> {:error, "intent confidence to low"}
    end
  end

  defp intention(intention_list, name) when is_atom(name) do
    case @intentions[name] do
      nil -> {:error, "not intention found"}
      _   -> {:ok, @intentions[name].intentions}
    end
  end
  defp intention(_), do: {:error, "invalid intention name"}
  defp intention, do: {:error, "cannot provide intention with no name"}
end
