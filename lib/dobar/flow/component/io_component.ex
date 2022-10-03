defmodule Dobar.Flow.Component.IOComponent do
  @moduledoc """
  Prints using Elixir's IO.inspect
  """

  use Dobar.Flow.Component

  @impl true
  def execute do
    IO.inspect "should i print or should i done?"
    {:ok, "nothing to do next"}
  end
end
