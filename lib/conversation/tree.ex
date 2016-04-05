defmodule Dobar.Conversation.Tree do

  defmacro __using__(_opts) do
    quote do
      import Dobar.Conversation.Tree
      @intentions %{}
    end
  end

  defmacro intention(name, do: block) when is_nil(block), do: nil
  defmacro intention(name, do: block) do
    compile_intention block
    # case block do
    #   {:capability, _, [intent | [entity]]} ->
    #     quote do
    #       @intentions Map.put(@intentions, unquote(name),
    #         [%{name: unquote(intent), entity: unquote(entity[:entity])}])
    #     end
    #   {_, _, capabilities} ->
    #     quote do
    #       intentions = Enum.map(unquote(Macro.escape capabilities), fn({:capability, _, x}) -> x end)
    #       |> Enum.map(fn(x) -> %{name: hd(x), entity: List.flatten(x)[:entity]} end)
    #       |> Enum.reduce([], fn(x, acc) -> [x | acc] end)
    #       |> Enum.reverse
    #       @intentions Map.put(@intentions, unquote(name), intentions)
    #     end
    #   _ ->
    #     quote do: @intentions @intentions
    # end
  end

  defmacro capability(name, entity: entity) do
    # IO.puts "capability is: #{inspect name}"
    # IO.inspect entity
  end

  defp compile_intention({:capability, _, [intent | [entity]]}) do
    quote do
      @intentions Map.put(@intentions, unquote(name),
        [%{name: unquote(intent), entity: unquote(entity[:entity])}])
    end
  end
  def compile_intention({_, _, capabilities}) do
    quote do
      intentions = Enum.map(unquote(Macro.escape capabilities), fn({:capability, _, x}) -> x end)
      |> Enum.map(fn(x) -> %{name: hd(x), entity: List.flatten(x)[:entity]} end)
      |> Enum.reduce([], fn(x, acc) -> [x | acc] end)
      |> Enum.reverse
      @intentions Map.put(@intentions, unquote(name), intentions)
    end
  end
  def compile_intention(_), do: nil
end
