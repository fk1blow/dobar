defmodule Dobar.Conversation.Intention do
  @moduledoc """
  This is the protocol that basically defines an intention which, by itself,
  represents a conversation tree.
  """

  alias Dobar.Conversation.Capability

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
        IO.puts "should test if can process next in a conversation or dialog"
        next_capability(Enum.reverse(@capabilities), intent)
      end

      def process_expected(expected, %Intent{} = old_intent, %Intent{} = new_intent) do
        IO.puts "should process the expected capability"
        expected_capability(expected, old_intent, new_intent)
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

  def next_capability([], _intent) do
    {:error, "cannot find a capability willing to become the next dialog"}
  end
  def next_capability([capability | tail], intent) do
    become_next = apply(capability.module, :become_next, [intent])
    case become_next do
      {:become_next, reply} -> {:next, capability}
      _ -> next_capability tail, intent
    end
  end

  def expected_capability(%Capability{module: module}, old_intent, new_intent) do
    apply(module, :handle_expected, [old_intent, new_intent])
  end
end
