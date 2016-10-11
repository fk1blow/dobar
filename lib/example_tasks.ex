# fetch_result = fn(timeout) ->
#   IO.puts "async fetch_result: #{inspect self}"
#   # :timer.sleep(timeout)
#   # IO.puts "_________________"
#   # raise "foo"

#   HTTPoison.get("http://elixir-lang.org/docs/stable/elixir/Task.html#content")
#   |> (&(IO.puts "res is: #{inspect elem(&1, 1) |> Map.get(:status_code)}")).()

#   %{res: nil}
# end






# compute = fn ->
#   IO.puts "async compute: #{inspect self}"
#   task = Task.async(fn -> fetch_result.(5000) end)
#   IO.puts "resulted computation"
#   # IO.puts "resulted computation... #{inspect Task.await(task)}"
#   task
# end

# run_f1 = fn ->
#   task = Task.async(compute)
#   IO.puts "spawned: #{inspect task}"

#   task |> Task.await(10000)
#   IO.puts "is alive? #{inspect Process.alive? task.pid}"


#   Task.async(fn ->
#     :timer.sleep(2000)
#     IO.puts Process.alive? task.pid
#   end) |> Task.await
# end

# compute = fn ->
#   IO.puts "entered..."
#   :timer.sleep(2000)
#   # res = HTTPoison.get!("http://elixir-lang.org/docs/stable/elixir/Task.html#content")
#   # :timer.sleep(3000)
#   # raise "asd"
#   # IO.puts "res of compute is: #{inspect res.status_code}"
#   IO.puts "computed???"
# end

# {:ok, pid} = Task.Supervisor.start_link(restart: :transient, max_restarts: 4)
# {:ok, pid} = Task.Supervisor.start_child(pid, compute)
# # task |> Task.await(2000)




# start_task = fn ->
#   IO.puts "starting a task..."
#   :timer.sleep(2000)
#   x = 20 / 0
#   {:ok, "task ok"}
# end

# Task.async(fn ->
#   try do
#     start_task.()
#   catch :error, reason ->
#     {:error, reason}
#   end
# end)

# receive do
#   message -> IO.puts "received: #{inspect message}"
# end
