defmodule Dobar.Interface.Adapter do
  @moduledoc """
  Interface adapter behaviour

  The interface adapter is the mediator between the outside world and DoBar,
  it facilitates conversations input and output, reactive and proactive.
  """

  def start_adapter(conf, interface), do: conf |> validate |> start(interface)

  defp validate(nil), do: {:error, "unable to read the adapter configuration"}
  defp validate(conf) do
    case Code.ensure_loaded? conf[:module] do
      true -> {:ok, conf}
      false -> {:error, "adapter module does not exist"}
    end
  end

  defp start({:error, reason}, _), do: {:error, reason}
  defp start({:ok, conf}, interface_pid) do
    opts = Keyword.merge([adapter_interface: interface_pid], optionals(conf[:opts]))
    apply(conf[:module], :start_link, [opts])
  end

  defp optionals(opts) when is_list(opts), do: opts
  defp optionals(_), do: []
end
