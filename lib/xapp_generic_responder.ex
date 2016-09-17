defmodule Dobar.Xapp.GenericResponder do
  use Dobar.Responder

  on :say_time, data: %{features: features} do
    IO.puts "say time matched...: #{inspect features}"
  end
end
