defmodule Dobar.Kapyz.Capability.AddMessageBody do
  use Dobar.Kapyz.Capability, name: :add_message_body

  alias Dobar.Model.Intent
  alias Dobar.Model.Capability

  def react(old_intent, %Intent{} = new_intent) do
    # IO.puts "and the message is....."
    IO.puts "new intent is: #{inspect new_intent}"

    # entities = Map.merge(old_intent.entities, new_intent.entities)
    # intent = Map.put old_intent, :entities, entities
    # capability = %Capability{context: nil, intent: %Intent{}}
    # GenEvent.notify :intent_events, {:capability_evaluated, capability}
  end
end
