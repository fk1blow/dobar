defmodule Dobar.Interface.Receiver.Text do
  @behaviour Dobar.Interface.Receiver

  def parse(_) do
    IO.puts "should be able to parse text input"
  end
end
