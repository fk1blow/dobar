defmodule Dobar.Conversation.Intention do
  @moduledoc """
  This is the protocol that basically defines an intention which, by itself,
  represents a conversation tree.

  Its roles is to process the capabilities and respond accordingly when
  theres a need for the next dialog capability or the expected capability
  intent process.
  """

  alias Dobar.Conversation.Model.Capability

  defmacro __using__(_opts) do
    quote do
      import Dobar.Conversation.Intention

      @capabilities []
      @before_compile Dobar.Conversation.Intention
    end
  end

  defmacro __before_compile__(_env) do
    alias Dobar.Model.Intent

    quote do
      def process_next(%Intent{} = intent) do
        next_capability(Enum.reverse(@capabilities), intent)
      end

      def process_expected(expected, %Intent{} = old_intent, %Intent{} = new_intent) do
        expected_capability(expected, old_intent, new_intent)
      end

      defp next_capability([], _intent) do
        {:error, "cannot find a capability willing to become the next dialog"}
      end
      defp next_capability([capability | tail], intent) do
        become_next = apply(capability.module, :become_next, [intent])
        case become_next do
          {:become_next, reply} -> {:next, capability}
          _ -> next_capability tail, intent
        end
      end

      defp expected_capability(%Capability{module: module}, old_intent, new_intent) do
        apply(module, :handle_expected, [old_intent, new_intent])
      end
    end
  end

  defmacro capability(name, entity: entity, module: module) do
    quote do
      {module, _} = Code.eval_quoted(unquote module)
      capability = %Capability{name: unquote(name), module: module,
        entitiy: unquote(entity)}
      @capabilities [capability | @capabilities]
    end
  end
end
