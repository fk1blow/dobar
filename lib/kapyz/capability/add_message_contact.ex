defmodule Dobar.Kapyz.Capability.AddMessageContact do
  use Dobar.Kapyz.Capability, name: :add_message_contact

  alias Dobar.Model.Intent
  alias Dobar.Model.Capability

  def react(%Intent{} = intent) do
    IO.puts "woowooo, a ajuns aici-sa"
    IO.inspect intent
  end
end
