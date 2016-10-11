defmodule Dobar.Error do
  defmodule EvaluationError do
    @type t :: %__MODULE__{
      reason: binary,
      other: any
    }

    defstruct reason: nil,
              other: nil
  end
end
