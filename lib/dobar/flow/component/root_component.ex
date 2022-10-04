defmodule Dobar.Flow.Component.RootComponent do
  @moduledoc """
  The root component
  """

  use Dobar.Flow.Component

  @impl true
  def execute do
    IO.puts "oooo i should be the kick"
    {:ok, "next is: Dobar.Flow.Component.IO"}
  end
end
