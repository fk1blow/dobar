defmodule Dobar.InterfaceEvents do
  @server __MODULE__

  def start_link, do: GenEvent.start_link [{:name, @server}]
end
