defmodule Dobar.Effect.Runner do
  use GenServer

  alias Dobar.Effect
  alias Dobar.Robot

  def start_link(opts \\ [name: __MODULE__]) do
    IO.puts "____________"
    GenServer.start_link __MODULE__, [], name: opts[:name]
  end

  def start_effect(pid, [robot: %Robot{} = robot, effect: %Effect{} = effect]) do
    GenServer.cast pid, {:start_effect, robot, effect}
  end

  def init(_) do
    {:ok, %{tasks: []}}
  end

  def handle_cast({:start_effect, robot, effect}, %{tasks: tasks} = state) do
    ref = make_ref
    timer = Process.send_after self, {:effect_timeout, ref}, 1000

    task = Task.Supervisor.async_nolink Dobar.Effect.Task, fn ->
      # raise "so let's see"
      # 20 / 0
      :timer.sleep 2000
      IO.puts "hoooorayyyyyyyyyyyy"
    end

    IO.puts "task created: #{inspect task}"

    {:noreply, Map.merge(state, %{tasks: [{ref, task} | tasks]})}
  end

  def handle_info({:effect_timeout, ref}, state) do
    IO.puts "task timed out: #{inspect ref}"
    IO.puts "state is: #{inspect state}"
    {:noreply, state}
  end

  def handle_info({reference, :ok}, state) do
    IO.puts "message from task: #{inspect reference}"
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, pid, :normal}, state) do
    IO.puts "task finished: #{inspect ref}"
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, pid, reason}, state) do
    IO.puts "task finished: #{inspect ref}"
    {:noreply, state}
  end

  # use Supervisor

  # alias Dobar.Effect
  # alias Dobar.Robot

  # def start_link(opts \\ [name: __MODULE__]) do
  #   Supervisor.start_link __MODULE__, [], name: opts[:name]
  # end

  # # def start_link(opts) do
  # #   import Supervisor.Spec
  # #   children = [
  # #     supervisor(Task.Supervisor, [[name: Effector.Tasks]])
  # #   ]
  # #   Task.Supervisor.start_link children
  # #   # supervise(children, name: opts[:name], strategy: :simple_one_for_one)
  # # end

  # def start_child(pid, [robot: %Robot{} = robot, effect: %Effect{} = effect]) do
  #   # IO.puts "robot: #{inspect robot}"
  #   # IO.puts "effect: #{inspect effect}"
  #   # Supervisor.start_child(pid, [[effect: effect]])
  #   # IO.puts "pid: #{inspect pid}"

  #   Task.Supervisor.start_child pid, fn ->
  #   #   # if random >= 5, do: raise "not so okkkkkkkkkkk"
  #     IO.puts "ok...."
  #   end
  # end

  # def init(_) do
  #   children = [
  #     # this should be a dynamic task instead of this sthi
  #     supervisor(Task.Supervisor, [[name: Effector.Supervisor]])
  #   ]
  #   supervise(children, strategy: :one_for_one)
  # end
end
