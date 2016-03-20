defmodule Dobar.Kapyz.Error do
  defmodule NoIntentHandlerError do
    defexception message: "no intent handler found"
  end

  defmodule InvalidIntentName do
    defexception message: "invalid intent name given"
  end
end
