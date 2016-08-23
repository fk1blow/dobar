defmodule Dobar.Interface.Receiver do
  @callback parse(Map.t) :: any
end
