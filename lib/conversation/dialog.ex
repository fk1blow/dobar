defmodule Dobar.Conversation.Dialog do

  defmacro __using__(_opts) do
    quote do
      import Dobar.Conversation.Dialog
      @conversations %{}
      @intention_module nil
    end
  end

  defmacro conversation(name, intention, do: block) when is_nil(block), do: nil
  defmacro conversation(name, intention, do: block) do
    quote do
      @intention_module unquote(intention)
      unquote(compile_intention block, name)
    end
  end

  defp compile_intention({:capability, _, [intent | entity]}, intent_name) do
    quote do
      @conversations Map.put(@conversations, unquote(intent_name),
        [%{name: unquote(intent), entity: unquote(entity[:entity])}])
    end
  end
  defp compile_intention({_, _, capabilities}, intent_name) do
    capabilities = Macro.escape capabilities
    quote do
      intentions = Enum.filter(unquote(capabilities), fn(item) ->
        case item do
          {:expect, _, _} -> true
          _ -> false
        end
      end)
      |> Enum.map(fn({:expect, _, x}) -> x end)
      |> Enum.map(fn(x) -> %{name: hd(x), entity: List.flatten(x)[:entity]} end)
      |> Enum.reduce([], fn(x, acc) -> [x | acc] end)
      |> Enum.reverse
      @conversations Map.put(@conversations, unquote(intent_name), intentions)
    end
  end
  defp compile_intention(_, _), do: nil
end
