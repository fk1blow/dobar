defmodule Dobar.Flow.Component.RootComponent do
  @moduledoc """
  The root component

  It has only one port named :output
  """

  use Dobar.Flow.Component

  @impl true
  def execute(state) do
    send_to_output("output", "hello dobar", state)
    {:ok, :inactive}
  end
end
