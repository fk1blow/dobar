defmodule Dobar.Saga.Definition do
  alias Dobar.Saga.Connection
  alias Dobar.Saga.Node

  @type t :: %__MODULE__{
          name: String.t(),
          connections: [Connection.t()],
          nodes: [Node.t()]
        }

  defstruct [:name, :connections, :nodes]
end
