defmodule Dobar.Model.Intent do
  @moduledoc """
  Dobar Intent
  """

  @type name       :: binary
  @type input      :: binary
  @type entities   :: map
  @type confidence :: float

  @type t :: %__MODULE__{
    name: name,
    input: input,
    entities: entities,
    confidence: confidence
  }

  defstruct name: nil,
            input: nil,
            entities: %{},
            confidence: 0.0
end
