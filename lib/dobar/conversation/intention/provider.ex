# TODO: useless and fucked up module - refactor it!
defmodule Dobar.Conversation.Intention.Provider do
  alias Dobar.Conversation.Intention

  # TODO: hardcoded and should be done dinamically
  @intentions [
    send_message: Intention.SendMessage,
    cancel_command: Intention.CancelCommand,
    change_recipient: Intention.ChangeRecipient,
    change_field: Intention.ChangeField,
    # create_alarm: Intention.CreateAlarm,
    switch_conversation: Intention.SwitchConversation,
    confirmation: Intention.Confirmation,
    purge_change_fields: Intention.PurgeChangeFields,
  ]

  def intention(name), do: get_intention(@intentions, name)

  defp get_intention([_head|_tail] = intentions, name) when is_atom(name) do
    case intentions[name] do
      nil -> {:error, "no intention found"}
      _   -> {:ok, intentions[name].intentions}
    end
  end
  defp get_intention(_intention_list, _), do: {:error, "invalid intention name"}
end
