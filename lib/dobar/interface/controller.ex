defmodule Dobar.Interface.Controller do
  require Logger
  alias Dobar.Interface.Receiver

  def parse_input({:text, input}) do
    Receiver.Text.parse input
  end
  def parse_input({:audio, input}) do
    Receiver.Audio.parse input
  end
  def parse_input({:data, data}) do
    IO.puts "shoud parse data, inside the Interface.Controller"
  end

  def send_output({:text, output}) do
    Logger.info "output: " <> output
  end
  def send_output({:data, data}) do
    Logger.debug "should send data, inside the Interface.Controller"
  end
end
