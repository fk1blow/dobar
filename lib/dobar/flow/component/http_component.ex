defmodule Dobar.Flow.Component.HttpComponent do
  @moduledoc """
  Component for making Http calls
  """

  use Dobar.Flow.Component

  @impl true
  def execute(state) do
    IO.puts "do some http shit"
    msg = fetch_from_input("input", state)
    IO.inspect("message from input: #{msg}")

    # IO.inspect(state)
    Process.sleep(1000)
    IO.puts "http responding..."

    send_to_output("result", msg <> " after some time", state)

    {:ok, :inactive}
  end
end
