defmodule Dobar.Interface do
  use GenServer

  def start_link(opts) do
    GenServer.start_link __MODULE__,
      [event_manager: opts[:event_manager], interface_conf: opts[:interface_conf]],
      name: __MODULE__
  end

  def init(args) do
    case Dobar.Interface.Adapter.start_adapter(args[:interface_conf] |> available_adapter) do
      {:ok, adapter} ->
        {:ok, %{adapter: adapter, event_manager: args[:event_manager]}}
      {:error, reason} ->
        {:stop, reason}
    end
  end

  def send(:text, message) do
    GenServer.cast __MODULE__, {:send, :text, message}
  end

  # TBD ????
  def handle_cast({:send, :text, message}, state) do
    apply state.module, :send, [message]
    {:noreply, state}
  end

  defp available_adapter(config_namespace) do
    Application.get_env(:dobar, config_namespace) |> Keyword.get(:adapter)
  end
end
