defmodule Dobar.Conversation.Tree do

  defmacro __using__(_opts) do
    quote do
      import Dobar.Conversation.Tree
      @intentions %{}
    end
  end

  defmacro intention(name, do: block) when is_nil(block), do: nil
  defmacro intention(name, do: block), do: compile_intention block, name

  defmacro capability(name, entity: entity) do
    # IO.puts "capability is: #{inspect name}"
    # IO.inspect entity
  end

  defp compile_intention({:capability, _, [intent | [entity]]}, intent_name) do
    quote do
      @intentions Map.put(@intentions, unquote(intent_name),
        [%{name: unquote(intent), entity: unquote(entity[:entity])}])
    end
  end
  defp compile_intention({_, _, capabilities}, intent_name) do
    capabilities = Macro.escape capabilities
    quote do
      intentions = Enum.map(unquote(capabilities), fn({:capability, _, x}) -> x end)
      |> Enum.map(fn(x) -> %{name: hd(x), entity: List.flatten(x)[:entity]} end)
      |> Enum.reduce([], fn(x, acc) -> [x | acc] end)
      |> Enum.reverse
      @intentions Map.put(@intentions, unquote(intent_name), intentions)
    end
  end
  defp compile_intention(_, _), do: nil
end
