defmodule Dobar.Interface.Adapter.Console.Connection do
  @moduledoc """
  The console adapter connection

  Shameless copy of Hedwig IM's console adapter
  url: https://github.com/hedwig-im/hedwig/blob/master/lib/hedwig/adapters/console.ex
  Hedwig-IM homepage: https://github.com/hedwig-im
  """

  @prompt_messages "µ˜ßåœ∑¬˚∆®©∑¡™¥£†¢ø∞π¬…ππø¡™∞†≤µåß≥≤µ∂ƒ∫©æ"

  def start_link(opts) do
    {user, 0} = System.cmd("whoami", [])
    clear_screen()
    show_banner()
    prompt_message = prompt_message(@prompt_messages)
    Task.start_link __MODULE__, :loop, [String.strip(user), opts[:adapter], prompt_message]
  end

  def loop(user, adapter, post) do
    user
    |> prompt(post)
    |> IO.ANSI.format
    |> IO.gets
    |> String.strip
    |> send_message(adapter)
    loop(user, adapter, post)
  end

  # def send(pid, message) do
  #   GenServer.cast pid, {:send, message}
  # end

  # def handle_cast({:send, message}, state) when is_binary(message) do
  #   IO.puts "should send the message to the console"
  #   {:noreply, state}
  # end

  defp send_message(message, adapter) do
    Kernel.send adapter, {:input, :text, message}
  end

  defp print(message) do
    message |> IO.ANSI.format |> IO.puts
  end

  defp clear_screen do
    print [:clear, :home]
  end

  defp prompt(name, message) do
    [:white, :bright, name, message, :normal, :default_color]
  end

  defp show_banner do
    print """
    DoBar console adapter - press Ctrl+c to exit.
    """
  end

  defp prompt_message(messages) do
    messages
    |> String.codepoints
    |> Enum.uniq
    |> Enum.random
    |> (&(" " <> &1 <> " ")).()
  end
end
