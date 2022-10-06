defmodule Dobar.Flow.Port do
  @type node_name :: String.t()
  @type node_pid :: term()#pid()

  @type t :: %__MODULE__{
          input: %{required(node_name()) => node_pid()},
          output: %{required(node_name()) => node_pid()}
        }

  defstruct [:input, :output]
end
