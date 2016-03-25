defmodule Dobar.Interface.Controller do
  def parse_input({:text, input}) do
    Dobar.Interface.Receiver.Text.parse input
  end

  def parse_input({:audio, data}) do
    IO.puts "audio input interface not implemented"
  end
end
