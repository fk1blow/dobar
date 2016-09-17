defmodule Dobar.Xapp.AnotherGenericResponder do
  use Dobar.Responder

  on :send_message, data: %{features: features} do
    IO.puts "send message matched...: #{inspect features}"
  end
end
