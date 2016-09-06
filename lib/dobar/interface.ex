defmodule Dobar.Interface do
  use GenServer
  alias Dobar.Interface.Adapter

  def start_link(opts) do
    GenServer.start_link __MODULE__, opts, name: __MODULE__
  end

  def init(args) do
    adapter = args[:interface_conf] |> available_adapter
    case Adapter.start_adapter(adapter, self) do
      {:ok, pid} ->
        Kernel.send pid, {:connect, []}
        {:ok, %{adapter: pid, event_manager: args[:event_manager]}}
      {:error, reason} ->
        {:stop, reason}
    end
  end

  def output(:text, message) do
    GenServer.cast __MODULE__, {:output, :text, message}
  end

  def handle_cast({:output, :text, message}, %{adapter: adapter} = state) do
    Kernel.send adapter, {:text, message}
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
