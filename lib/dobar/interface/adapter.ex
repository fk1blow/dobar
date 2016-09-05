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
      import Kernel, except: [send: 2]

      @behaviour Dobar.Interface.Adapter

      def send(:text, message) do
        GenServer.cast __MODULE__, {:send, :text, message}
      end

      defoverridable [send: 2]
    end
  end

  defcallback send(atom, String.t) :: term

  def start_adapter(module), do: module |> validate |> start(self)

  # Private

  defp validate(nil), do: {:error, "unable to use undefined or nil interface adapter"}
  defp validate(module) do
    case Code.ensure_loaded? module do
      true -> {:ok, module}
      false -> {:error, "adapter module does not exist"}
    end
  end

  defp start({:error, reason}, _), do: {:error, reason}
  defp start({:ok, module}, interface_pid),
    do: apply(module, :start_link, [[adapter_interface: interface_pid]])
end
