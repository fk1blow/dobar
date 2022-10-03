defmodule Dobar.Saga.Connection do
  @type t :: %__MODULE__{
          from: String.t(),
          to: String.t()
        }

  defstruct [:from, :to]
end
