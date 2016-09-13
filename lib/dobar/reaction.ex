defmodule Dobar.Reaction do
  @type t :: %__MODULE__{
    about: atom,
    text: binary,
    data: map
  }

  defstruct about: nil,
            text: nil,
            data: %{}
end
