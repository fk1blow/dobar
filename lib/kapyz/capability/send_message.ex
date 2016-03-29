defmodule Dobar.Kapyz.Capability.SendMessage do
  use Dobar.Kapyz.Capability, name: :send_message
  alias Dobar.Models.Intent

  # TODO: find out why this doesn't work
  def react(intent) do
    IO.puts "pfff, are si email???"
    IO.inspect intent
  end

  def react(%Intent{input: text}) do
    IO.puts "should react to the :send_text_message.ex intention"
    IO.puts "text data: #{inspect text}"
  end
end
