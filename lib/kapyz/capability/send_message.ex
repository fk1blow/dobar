defmodule Dobar.Kapyz.Capability.SendMessage do
  use Dobar.Kapyz.Capability, name: :send_message

  alias Dobar.Models.Intent
  alias Dobar.Spub.IntentHandler

  def react(%Intent{entities: %{app_name: app_name, contact: contact}}) do
    IO.puts "has application and contact; should require the text message"
  end

  def react(%Intent{entities: %{contact: contact}}) do
    IO.puts "has only the contact; should require the applicaiton to use"
  end

  def react(%Intent{entities: %{email: email}}) do
    IO.puts "has email; should require the application to use"
  end

  def react(%Intent{entities: %{}}) do
    IO.puts "xrx: should require the receiver"
    capabiltiy = %{dialog: "message_receiver"}
    GenEvent.notify :intent_events, {:capability_evaluated, capabiltiy}
  end
end
