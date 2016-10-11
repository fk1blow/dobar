defmodule Dobar.Effect.Runner.Entry do
  @type t :: %__MODULE__{
    id_ref: reference,
    timer: reference,
    task: Task.t
  }

  defstruct id_ref: nil,
             timer: nil,
              task: %Task{}
end
