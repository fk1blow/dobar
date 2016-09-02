defmodule Dobar.Interface.Adapter do
  @moduledoc """
  Interface adapter behaviour

  The interface adapter is the mediator between the outside world and DoBar,
  it facilitates conversations input and output, reactive and proactive.
  """

  use Behaviour

  defmacro __using__(_opts) do
    quote do
      use GenServer
      @behaviour Dobar.Interface.Adapter

      # def start_link do
      #   GenServer.start_link __MODULE__, [], name: __MODULE__
      # end

      # def connect(pid, opts) do
        # GenServer.call pid, {:connect, opts}
      # end

      def send(pid, {:send, :text, message}) do
        GenServer.call pid, {:send, :text, message}
      end

      # def handle_call({:connect, opts}, _from, state) do
      #   {:reply, nil, state}
      # end

      defoverridable [send: 2]
    end
  end

  defcallback connect :: term
  defcallback send(atom, String.t) :: term

  def start(namespace) do
    namespace
    |> interface_config
    |> available_adapter
    |> validate_adapter
    |> start_adapter
  end

  defp interface_config(namespace) do
    Application.get_env(:dobar, namespace) |> Keyword.get(:adapter)
  end

  defp available_adapter(nil), do: {:error, "no adapter found for :adapter config"}
  defp available_adapter(adapter), do: {:ok, adapter}

  defp validate_adapter({:error, reason}), do: {:error, reason}
  defp validate_adapter({:ok, module}) do
    case Code.ensure_loaded? module do
      true -> {:ok, module}
      false -> {:error, "adapter module does not exist"}
    end
  end

  defp start_adapter({:error, reason}), do: {:error, reason}
  defp start_adapter({:ok, module}) do
    {:ok, pid} = apply(module, :start_link, [])
    {:ok, module, pid}
  end
end
