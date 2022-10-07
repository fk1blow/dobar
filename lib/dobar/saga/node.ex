defmodule Dobar.Saga.Node do
  @type t :: %__MODULE__{
          component: String.t(),
          id: String.t(),
          is_root: boolean(),
          ports: Map.t()
        }

  defstruct [:component, :id, :is_root, :ports]

  use ExConstructor
end
