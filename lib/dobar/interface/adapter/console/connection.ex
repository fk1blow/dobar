defmodule Dobar.Interface.Adapter.Console.Connection do
  @moduledoc """
  The console adapter connection

  Shameless copy of Hedwig IM's console adapter
  url: https://github.com/hedwig-im/hedwig/blob/master/lib/hedwig/adapters/console.ex
  Hedwig-IM homepage: https://github.com/hedwig-im
  """

  use GenServer

  @prompt_messages "µ˜ßåœ∑¬˚∆®©∑¡™¥£†¢ø∞π¬…ππø¡™∞†≤µåß≥≤µ∂ƒ∫©æ"

  def start_link(opts) do
    {user, 0} = System.cmd("whoami", [])
    clear_screen()
    show_banner()
    prompt_message = prompt_message(@prompt_messages)
    GenServer.start_link __MODULE__,  [String.strip(user), opts[:adapter], prompt_message]
  end

  def init([user, adapter, prompt]) do
    Task.async(__MODULE__, :loop, [user, adapter, prompt])
    {:ok, %{user: user, adapter: adapter, prompt: prompt}}
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

  def send(pid, message) do
    GenServer.cast pid, message
  end

  def handle_cast(message, state) do
    output(message, state.user, state.prompt)
    {:noreply, state}
  end

  defp send_message(message, adapter) do
    Kernel.send adapter, {:input, :text, message}
  end

  defp print(message) do
    message |> IO.ANSI.format |> IO.puts
  end

  defp output(nil, _name, _prompt_message), do: nil
  defp output(msg, name, prompt_message) do
    print [:yellow, msg, :default_color]
  end

  defp clear_screen do
    print [:clear, :home]
  end

  defp prompt(name, prompt_message) do
    [:white, :bright, name, prompt_message, :normal, :default_color]
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
