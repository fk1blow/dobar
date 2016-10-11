defmodule Dobar.Effect do
  @type t :: %__MODULE__{
    reaction:   Dobar.Reaction.t,
    responders: [...],
    robot:      binary | atom
  }

  defstruct reaction: %Dobar.Reaction{},
          responders: [],
               robot: :undefined_waka

  defmacro __using__(_) do
    quote do
      import Dobar.Effect
      @before_compile Dobar.Effect
    end
  end

  defmacro on(message, do: block) do
    quote do
      def handle_on(unquote(message), var!(interface)), do: fn -> unquote(block) end
    end
  end

  defmacro on(message) do
    raise "You cannot declare an effect that does 'nothing'"
  end

  defmacro __before_compile__(_env) do
    quote do
      # catch non-matches thereby avoiding runtime errors
      def handle_on(_), do: nil
      def handle_on(_, _), do: nil
    end
  end
end
