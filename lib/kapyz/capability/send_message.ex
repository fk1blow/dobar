defmodule Dobar.Kapyz.Capability.SendMessage do
  use Dobar.Kapyz.Capability, name: :send_text_message
  alias Dobar.Kapyz.Intent

  def react(%Intent{text: text}) do
    IO.puts "should react to the :send_text_message.ex intention"
    IO.puts "text data: #{inspect text}"
  end
end
