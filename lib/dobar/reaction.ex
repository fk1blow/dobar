defmodule Dobar.Reaction do
  alias Dobar.Intent

  @type t :: %__MODULE__{
    about: atom,
    text: binary,
    features: map,
    trigger: Intent.t,
    other: any
  }

  defstruct about: nil,
            text: nil,
            features: %{},
            trigger: %Intent{},
            other: nil
end
