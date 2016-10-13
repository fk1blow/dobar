defmodule Dobar.Interface.Adapter.Console.Connection do
  @moduledoc """
  The console adapter connection

  Shameless copy of Hedwig IM's console adapter
  url: https://github.com/hedwig-im/hedwig/blob/master/lib/hedwig/adapters/console.ex
  Hedwig-IM homepage: https://github.com/hedwig-im
  """

  @prompts "µ˜ßåœ∑¬˚∆®©∑¡™¥£†¢ø∞π¬…ππø¡™∞†≤µåß≥≤µ∂ƒ∫©æ"

  def start_link(opts) do
    {user, 0} = System.cmd("whoami", [])
    clear_console()
    show_banner()
    prompt_message = prompt_message(@prompts)
    opts = [String.strip(user), opts[:adapter], prompt_message]
    pid = spawn_link(__MODULE__, :init, opts)
    {:ok, pid}
  end

  def init(user, adapter, prompt) do
    Task.async(__MODULE__, :repl, [user, adapter, prompt])
    loop(user, adapter, prompt)
  end

  def loop(user, adapter, prompt) do
    receive do
      {:output, message} ->
        output(message, user, prompt)
        loop(user, adapter, prompt)
      _ ->
        loop(user, adapter, prompt)
    end
  end

  def repl(user, adapter, prompt) do
    user
    |> prompt(prompt)
    |> IO.ANSI.format
    |> IO.gets
    |> String.strip
    |> send_message(adapter)
    repl(user, adapter, prompt)
  end

  defp send_message(message, adapter) do
    Kernel.send adapter, {:input, :text, message}
  end

  defp print(message) do
    message |> IO.ANSI.format |> IO.puts
  end

  defp output(nil, _name, _prompt_message), do: nil
  defp output(msg, name, prompt_message) do
    print [:green, msg, :default_color]
  end

  defp prompt(name, prompt_message) do
    [:white, :bright, name, prompt_message, :normal, :default_color]
  end

  defp clear_console do
    print [:clear, :home]
  end

  defp show_banner do
    print """
    DoBar console adapter - press Ctrl+c to exit.
    """
  end

  defp prompt_message(prompts) do
    prompts
    |> String.codepoints
    |> Enum.uniq
    |> Enum.random
    |> (&(" " <> &1 <> " ")).()
  end
end
