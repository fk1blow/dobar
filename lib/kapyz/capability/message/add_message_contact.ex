defmodule Dobar.Kapyz.Capability.AddMessageContact do
  use Dobar.Kapyz.Capability, name: :add_message_contact

  alias Dobar.Model.Intent
  alias Dobar.Model.Capability

  def react(old_intent, %Intent{} = new_intent) do
    IO.puts "woowooo, a ajuns aici-sa"
    IO.puts "old intent: #{inspect old_intent}"
    IO.puts "new intent: #{inspect new_intent}"
  end
end
