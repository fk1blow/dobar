# TODO: rename to Dobar.Model.Intent (singular model)
defmodule Dobar.Models.Intent do
  defstruct name: nil, input: nil, entities: %{}, confidence: 0
end
