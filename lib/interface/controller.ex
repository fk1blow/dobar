defmodule Dobar.Interface.Controller do
  use GenServer

  alias Dobar.Interface.Receiver
  alias Dobar.Spub.InterfaceHandler

  @name __MODULE__

  def start_link do
    GenServer.start_link @name, [], name: @name
  end

  def init(_) do
    GenEvent.add_handler :interface_events, InterfaceHandler, nil
    {:ok, nil}
  end

  def parse_input({:text, input}) do
    GenServer.cast @name, {:parse_text, input}
  end
  def parse_input({:audio, input}) do
    GenServer.cast @name, {:parse_audio, input}
  end
  def parse_input({:data, data}) do
    GenServer.cast @name, {:parse_data, data}
  end

  def send_output({:text, output}) do
    GenServer.cast @name, {:send_text, output}
  end
  def send_output({:data, data}) do
    GenServer.cast @name, {:send_data, data}
  end

  # callbacks
  #

  def handle_cast({:parse_text, input}, _state) do
    Receiver.Text.parse input
    {:noreply, nil}
  end

  def handle_cast({:parse_audio, input}, _state) do
    Receiver.Audio.parse input
    {:noreply, nil}
  end

  def handle_cast({:parse_data, data} _state) do
    IO.puts "shoud parse data, inside the Interface.Controller"
    {:noreply, nil}
  end

  def handle_cast({:send_text, output}, _state) do
    IO.puts "should send text, output inside the Interface.Controller"
    {:noreply, nil}
  end

  def handle_cast({:send_data, data}, _state) do
    IO.puts "should send data, inside the Interface.Controller"
    {:noreply, nil}
  end
end
