defmodule Dobar.Interface.Adapter.Console.Connection do
  use GenServer

  def start_link do
    {user, 0} = System.cmd("whoami", [])
    clear_screen()
    show_banner()
    Task.start_link __MODULE__, :loop, [user]
  end

  def loop(user) do
    user
    |> prompt
    |> IO.ANSI.format
    |> IO.gets
    |> String.strip
    |> send_message
    loop(user)
  end

  def send(pid, message) do
    GenServer.cast pid, {:send, message}
  end

  def handle_cast({:send, message}, state) when is_binary(message) do
    IO.puts "should send the message to the console"
    {:noreply, state}
  end

  defp send_message(message) do
    IO.puts "message to send: #{inspect message}"
  end

  defp print(message) do
    message |> IO.ANSI.format |> IO.puts
  end

  defp clear_screen do
    print [:clear, :home]
  end

  defp prompt(name) do
    [:white, :bright, name, "> ", :normal, :default_color]
  end

  defp show_banner do
    print """
    DoBar console adapter - press Ctrl+c to exit.
    """
  end
end
