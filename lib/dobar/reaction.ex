defmodule Dobar.Reaction do
  alias Dobar.Model.Intent

  @type t :: %__MODULE__{
    about: atom,
    text: binary,
    features: map,
    trigger: Intent.t,
    other: map
  }

  defstruct about: nil,
            text: nil,
            features: %{},
            trigger: %Intent{},
            other: %{}
end
