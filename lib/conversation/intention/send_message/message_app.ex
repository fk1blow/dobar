defmodule Dobar.Conversation.Intention.MessageApp do
  @behaviour Dobar.Conversation.Capability

  @next_reply "what's the application you would like to use?"
  @halt_reason "cannot find the application name in the provided reply!"

  alias Dobar.Model.Intent

  def become_next(%Intent{} = intent) do
    # is_nil intent.entities[:app_name]
    unless intent.entities[:app_name] do
      {:become_next, @next_reply}
    end
  end

  def handle_expected(%Intent{} = intent) do
    if intent.entities[:app_name] do
      # todo: should add the app_name entity to the intent
      {:ok, intent}
    else
      {:error, @halt_reason}
    end
  end
end
