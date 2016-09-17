defmodule Dobar.Xapp.GenericResponder do
  use Dobar.Responder

  on :say_time, data: %{data: data} do
    IO.puts "say time matched...: #{inspect data}"
  end
end
