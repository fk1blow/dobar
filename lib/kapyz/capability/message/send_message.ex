defmodule Dobar.Kapyz.Capability.SendMessage do
  use Dobar.Kapyz.Capability, name: :send_message

  alias Dobar.Model.Intent
  alias Dobar.Model.Capability

  def react(_, %Intent{entities: %{app_name: app_name, contact: contact}} = intent) do
    IO.puts "has application and contact; should require the text message"
    capability = %Capability{context: %{state: "message_body"}, intent: intent}
    GenEvent.notify :intent_events, {:capability_evaluated, capability}
  end

  def react(_, %Intent{entities: %{app_name: app_name, email: email}} = intent) do
    IO.puts "has application and email; should require the text message"
    capability = %Capability{context: %{state: "message_body"}, intent: intent}
    GenEvent.notify :intent_events, {:capability_evaluated, capability}
  end

  def react(old_intent, %Intent{entities: %{email: _}} = intent) do
    IO.puts "has only the email entity; should require the application to use"
    capability = %Capability{context: %{state: "message_application"}, intent: intent}
    GenEvent.notify :intent_events, {:capability_evaluated, capability}
  end

  def react(old_intent, %Intent{entities: %{contact: _}} = intent) do
    IO.puts "has only the email entity; should require the application to use"
    capability = %Capability{context: %{state: "message_application"}, intent: intent}
    GenEvent.notify :intent_events, {:capability_evaluated, capability}
  end

  def react(old_intent, %Intent{entities: %{}} = intent) do
    IO.puts "has only the intent; should require contact or email"
    capability = %Capability{context: %{state: "message_receiver"}, intent: intent}
    GenEvent.notify :intent_events, {:capability_evaluated, capability}
  end
end
