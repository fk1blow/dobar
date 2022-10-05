defmodule Dobar.Saga do
  @moduledoc """
  Dobar.Saga doc
  """

  @type t :: %__MODULE__{
          name: String.t(),
          version: String.t(),
          nodes: [Dobar.Saga.Node.t()],
          connections: [Dobar.Saga.Connection.t()]
        }

  defstruct [:name, :version, :nodes, :connections]
end
