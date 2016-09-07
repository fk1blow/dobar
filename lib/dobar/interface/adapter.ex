defmodule Dobar.Interface.Adapter do
  @moduledoc """
  Interface adapter behaviour

  The interface adapter is the mediator between the outside world and DoBar,
  it facilitates conversations input and output, reactive and proactive.
  """

  # I don't like that starting is api interface but connecting - maybe make them
  # both message-passing(or the other way around)
  def start_adapter(module, interface), do: module |> validate |> start(interface)

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
