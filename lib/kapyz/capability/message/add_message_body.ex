defmodule Dobar.Kapyz.Capability.AddMessageBody do
  use Dobar.Kapyz.Capability, name: :add_message_body

  alias Dobar.Model.Intent
  alias Dobar.Model.Capability
  alias Dobar.Model.Response

  def react(%Intent{entities: %{app_name: _, email: _}} = intent, _) do
    capability = %Capability{context: nil, intent: %Intent{}}
    GenEvent.notify :intent_events, {:capability_evaluated, capability}

    response = %Response{text: "ok, now it should send the message"}
    GenEvent.notify :interface_events, {:response_evaluated, response}
  end

  def react(%Intent{entities: %{app_name: _, contact: _}} = intent, _) do
    capability = %Capability{context: nil, intent: %Intent{}}
    GenEvent.notify :intent_events, {:capability_evaluated, capability}

    response = %Response{text: "ok, now it should send the message"}
    GenEvent.notify :interface_events, {:response_evaluated, response}
  end
end
