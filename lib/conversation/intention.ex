defmodule Dobar.Conversation.Intention do
  @moduledoc """
  ## TODO

  1. 'draw' a more simpler description of the `Intention` protocol
  2. add fucking typespecs to `process_next` and `process_expected`
  3. define the api of the this protocol(`process_next` and `process_expected`

  ## Description

  This is the protocol that basically defines an intention, which represents a
  preestablished command that dobar might understand.
  It usually consists of entities(frames, slots) that have to be completed
  in order to consider the intention resolved - user gets the command's answer.

  Its roles is to process the capabilities and respond accordingly when
  theres a need for the next dialog capability or the expected one.
  """

  alias Dobar.Conversation.Model.Capability

  defmacro __using__(_opts) do
    quote do
      import Dobar.Conversation.Intention

      @capabilities []
      @enderbility nil
      @before_compile Dobar.Conversation.Intention
    end
  end

  defmacro __before_compile__(_env) do
    alias Dobar.Model.Intent

    quote do
      def process_next(%Intent{} = intent) do
        next_capability(Enum.reverse(@capabilities), intent)
      end

      def process_expected(expected, old_intent, new_intent) do
        expected_capability(expected, old_intent, new_intent)
      end

      defp next_capability([], intent) do
        case ending_capability(intent) do
          {:ok, reply} ->
            {:ended, reply, intent}
          _ ->
            {:error, "cannot find a capability willing to become the next dialog"}
        end
      end

      defp next_capability([capability | tail], intent) do
        become_next = apply(capability.module, :become_next, [intent])
        case become_next do
          {:ok, reply} -> {:next, reply, capability}
          _ -> next_capability(tail, intent)
        end
      end

      defp expected_capability(%Capability{module: module}, old_intent, new_intent) do
        expected = apply(module, :handle_expected, [old_intent, new_intent])
        case expected do
          {:ok, intent} -> {:continue, intent}
          {:halt, reason} -> {:halt, reason}
        end
      end

      defp ending_capability(intent) do
        module = @enderbility.module
        apply(module, :handle_ending, [intent])
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

  defmacro ending(name, module: module) do
    quote do
      {module, _} = Code.eval_quoted(unquote module)
      capability = %Capability{name: unquote(name), module: module}
      @enderbility capability
    end
  end
end
