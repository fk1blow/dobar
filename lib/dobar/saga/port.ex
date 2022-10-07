defmodule Dobar.Flow.Port do
  @type node_name :: String.t()
  @type node_pid :: term() | pid()

  @type t :: %__MODULE__{
          inputs: %{required(node_name()) => node_pid()} | nil,
          outputs: %{required(node_name()) => node_pid()} | nil
        }

  defstruct [:inputs, :outputs]
end
