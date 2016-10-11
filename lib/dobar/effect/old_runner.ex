defmodule Dobar.Effect.OldRunner do
  use GenServer

  alias Dobar.Reaction
  alias Dobar.Effect

  def start_link([effect: %Effect{} = effect]) do
    IO.puts "effect: #{inspect effect}"

    random = :rand.uniform(10)

    Task.start(fn ->
      :timer.sleep(2000)
      # if random >= 5, do: raise "not so okkkkkkkkkkk"
      IO.puts "ok...."
    end)
  end
end
