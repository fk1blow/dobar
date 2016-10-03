defmodule Dobar.Evaluator do
  # def evaluate({:text, input}) do
  def evaluate do
    {:ok, pid} = Task.Supervisor.start_link()
    task = Task.Supervisor.async_nolink(pid, fn ->
      # Do something
      # raise "baaaaaad"
      :timer.sleep(1100)
    end)
    Task.await(task, 1000)
  end
end
