defmodule Dobar.Conversation.Intention.MessageBody do
  @behaviour Dobar.Conversation.Capability

  @next_reply "what's the application you would like to use?"
  @halt_reply "cannot find the application name in the provided reply!"

  alias Dobar.Model.Intent

  def become_next(%Intent{} = intent) do
    intent.entities[:body]
  end

  def handle_intention(%Intent{} = intent) do
    if intent.entities[:body] do
      {:next, @next_reply}
    else
      {:halt, @halt_reply}
    end
  end
end
