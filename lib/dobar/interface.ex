defmodule Dobar.Interface do
  use GenServer
  alias Dobar.Interface.Adapter

  def start_link(opts) do
    GenServer.start_link __MODULE__, opts, name: __MODULE__
  end

  def init(args) do
    args[:interface_conf]
    |> available_adapter
    |> start_adapter(self, args[:event_manager])
  end

  def output(:text, message) do
    GenServer.cast __MODULE__, {:output, :text, message}
  end

  # Callbacks

  def handle_cast({:output, :text, message}, %{adapter: adapter} = state) do
    Kernel.send adapter, {:text, message}
    {:noreply, state}
  end

  # received from the adapter and used as a callback for input triggers
  def handle_info({:input, :text, message}, %{event_manager: nil} = state) do
    {:noreply, state}
  end
  def handle_info({:input, :text, message}, %{event_manager: event_manager} = state) do
    GenEvent.notify(event_manager, {:input, :text, message})
    {:noreply, state}
  end

  # Private

  defp available_adapter(config_namespace) do
    Application.get_env(:dobar, config_namespace) |> Keyword.get(:adapter)
  end

  def start_adapter(adapter, interface, event_manager) do
    case Adapter.start_adapter(adapter, interface) do
      {:ok, pid} -> {:ok, %{adapter: pid, event_manager: event_manager}}
      {:error, reason} -> {:stop, reason}
    end
  end
end
