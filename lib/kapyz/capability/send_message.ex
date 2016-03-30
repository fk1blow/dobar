defmodule Dobar.Kapyz.Capability.SendMessage do
  use Dobar.Kapyz.Capability, name: :send_message

  alias Dobar.Model.Intent

  def react(%Intent{entities: %{app_name: app_name, contact: contact}}) do
    IO.puts "has application and contact; should require the text message"
  end

  def react(%Intent{entities: %{app_name: app_name, email: email}}) do
    IO.puts "has application and email; should require the text message"
  end

  def react(%Intent{entities: %{contact: contact}}) do
    IO.puts "has only the contact; should require the application to use"
  end

  def react(%Intent{entities: %{email: email}}) do
    IO.puts "has email; should require the application to use"
  end

  def react(%Intent{entities: %{}}) do
    capabiltiy = %{dialog: "message_receiver"}
    GenEvent.notify :intent_events, {:capability_evaluated, capabiltiy}
  end
end
