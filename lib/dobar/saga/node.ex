defmodule Dobar.Saga.Node do
  @type t :: %__MODULE__{
          module: atom(),
          id: String.t(),
          is_root: boolean()
        }

  defstruct [:module, :id, :is_root]
end
