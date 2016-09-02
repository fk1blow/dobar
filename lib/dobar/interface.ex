defmodule Dobar.Interface do
  use GenServer

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    case Dobar.Interface.Adapter.start(Dialog.Interface) do
      {:ok, module, adapter} -> {:ok, %{adapter: adapter, module: module}}
      {:error, reason} -> {:stop, reason}
    end
  end

  def send(:text, message) do
    GenServer.cast __MODULE__, {:send, :text, message}
  end

  # TBD
  def handle_cast({:send, :text, message}, state) do
    apply state.module, :send, [message]
    {:noreply, state}
  end
end
