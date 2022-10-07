defmodule Dobar.Saga.Connection do
  @type t :: %__MODULE__{
          id: String.t(),
          from: String.t(),
          to: String.t()
        }

  defstruct [:id, :from, :to]

  use ExConstructor
end
