defmodule Dobar.Flow.Component.IOComponent do
  @moduledoc """
  Prints using Elixir's IO.inspect
  """

  use Dobar.Flow.Component

  @impl true
  def execute(state) do
    IO.puts "should i print or should i done?"

    msg = fetch_from_input("input", state)

    IO.inspect msg

    {:ok, :inactive}
  end
end
