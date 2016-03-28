defmodule Dobar.Intent.Resolver do
  @moduledoc """
  Has the responsability to resolve a text expression, to an intent.
  It communicates with an external service in order to evaluate the input.
  Right now, the only current available service is wit.ai
  """

  use GenServer
end
