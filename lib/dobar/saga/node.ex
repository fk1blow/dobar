defmodule Dobar.Saga.Node do
  @type t :: %__MODULE__{
          module: atom(),
          name: String.t(),
          is_root: boolean()
        }

  defstruct [:module, :name, :is_root]
end
