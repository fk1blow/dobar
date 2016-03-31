defmodule Dobar.Model.Capability do
  # TODO: should the context default to `%{}` ?
  defstruct context: nil, intent: %Dobar.Model.Intent{}
end
