defmodule Dobar.Flow.Network do
  @deprecated "use the Dobar.Saga.t() instead"

  @moduledoc """
  It manages parsing, loading and initializing a network

  The network is responsible of handling graphs, loading, parsing them and mostly
  transforming them into a network of nodes and connections, to be handled by
  the flow Scheduler
  """

  @type t :: %__MODULE__{
          name: String.t(),
          nodes: [Dobar.Saga.Node.t()],
          connections: [Dobar.Saga.Connection.t()]
        }

  defstruct [:name, :nodes, :connections]
end
