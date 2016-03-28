defmodule Dobar.Interface.Receiver.Audio do
  @behaviour Dobar.Interface.Receiver

  def parse(_) do
    IO.puts "should be able to parse audio input"
  end
end
