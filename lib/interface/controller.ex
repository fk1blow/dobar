defmodule Dobar.Interface.Controller do
  alias Dobar.Interface.Receiver

  def parse_input({:text, input}) do
    Receiver.Text.parse input
  end

  def parse_input({:audio, input}) do
    Receiver.Audio.parse input
  end
end
