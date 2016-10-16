defmodule Dobar.Effect.Runner do
  use GenServer

  alias Dobar.Effect
  alias Dobar.Effect.Runner.Entry

  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link __MODULE__, [], name: opts[:name]
  end

  def run(pid, %Effect{} = effect, optional) do
    GenServer.cast pid, {:start_effect, effect, optional}
  end

  def init(_) do
    {:ok, []}
  end

  def handle_cast({:start_effect, %Effect{} = effect, optional}, pool) do
    pool =
      effect.responders
      |> Enum.map(&(apply(&1, :handle_on, [effect.reaction, optional])))
      |> Enum.map(&create_task/1)
      |> Enum.map(&new_entry/1)
      |> Enum.concat(pool)
      |> Enum.filter(&(is_nil(&1) === false))
    {:noreply, pool}
  end

  def handle_info({:effect_timeout, ref}, pool) do
    pool =
      ref
      |> find_entry_ref(pool)
      |> shutdown_entry_task
      |> remove_entry(pool)
    {:noreply, pool}
  end

  def handle_info({ref, :ok}, pool) do
    {:noreply, pool}
  end

  def handle_info({:DOWN, ref, :process, pid, _reason}, pool) do
    entry = ref |> find_entry_task(pool)
    case entry do
      entry when is_nil(entry) -> nil
      %Entry{timer: timer}     -> :erlang.cancel_timer timer
    end
    {:noreply, entry |> remove_entry(pool)}
  end
  # this is when the task finishes and calls with a result(`_msg` in this case)
  def handle_info({ref, _msg}, state) when is_reference(ref) do
    {:noreply, state}
  end

  defp create_task(cb) when is_function cb do
    Task.Supervisor.async_nolink Dobar.Effect.Task, cb
  end
  defp create_task(_), do: nil

  defp new_entry(%Task{} = task) do
    timer_ref = make_ref
    timer = Process.send_after self, {:effect_timeout, timer_ref}, 5000
    %Entry{id_ref: timer_ref, timer: timer, task: task}
  end
  defp new_entry(_), do: nil

  defp find_entry_task(ref, [_|_] = pool) do
    pool |> Enum.find(nil, fn %Entry{task: task} -> ref === task.ref end)
  end
  defp find_entry_task(_ref, _pool), do: nil

  defp find_entry_ref(ref, [_|_] = pool) do
    pool |> Enum.find(nil, fn %Entry{id_ref: id_ref} -> ref === id_ref end)
  end
  defp find_entry_ref(_ref, _pool), do: nil

  defp shutdown_entry_task(nil), do: nil
  defp shutdown_entry_task(%Entry{task: task} = entry) do
    Task.shutdown(task, 0)
    entry
  end

  defp remove_entry(nil, pool), do: pool
  defp remove_entry(%Entry{id_ref: ref} = entry, [_|_] = pool) do
    pool |> Enum.filter(fn %{id_ref: id_ref} -> id_ref !== ref end)
  end
  defp remove_entry(_, pool), do: pool
end
