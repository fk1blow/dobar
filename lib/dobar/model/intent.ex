defmodule Dobar.Model.Intent do
  @type t :: %__MODULE__{
    name: binary,
    input: binary,
    entities: map,
    confidence: float
  }

  defstruct name: nil,
            input: nil,
            entities: %{},
            confidence: 0.0
end
