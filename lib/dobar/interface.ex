defmodule Dobar.Interface do
  use GenServer
  alias Dobar.Interface.Adapter

  def start_link(opts) do
    GenServer.start_link __MODULE__,
      [event_manager: opts[:event_manager], interface_conf: opts[:interface_conf]],
      name: __MODULE__
  end

  def init(args) do
    case Adapter.start_adapter(args[:interface_conf] |> available_adapter) do
      {:ok, adapter} ->
        Kernel.send adapter, {:connect, []}
        {:ok, %{adapter: adapter, event_manager: args[:event_manager]}}
      {:error, reason} ->
        {:stop, reason}
    end
  end

  def send(:text, message) do
    GenServer.cast __MODULE__, {:send, :text, message}
  end

  # TODO: :send should rather be :outpout
  def handle_cast({:send, :text, message}, %{adapter: adapter} = state) do
    Kernel.send adapter, {:send, :text, message}
    {:noreply, state}
  end

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
end
