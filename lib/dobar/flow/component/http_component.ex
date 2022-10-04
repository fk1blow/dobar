defmodule Dobar.Flow.Component.HttpComponent do
  @moduledoc """
  Component for making Http calls
  """

  use Dobar.Flow.Component

  @impl true
  def execute do
    Process.sleep(1000)
    {:ok, "next is: Dobar.Flow.Component.IO"}
  end
end
