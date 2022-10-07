defmodule Dobar.Flow.Component.PeriodicalComponent do
  @moduledoc """
  At each specified intervals, it sends a packet through the network
  """

  use Dobar.Flow.Component

  @impl true
  def execute(state) do
    send_to_output("output", "hello dobar", state)
    Process.send_after(self(), :rerun, 4000)
    {:ok, :inactive}
  end

  def handle_info(:rerun, state) do
    execute(state)
    {:noreply, state}
  end
end
