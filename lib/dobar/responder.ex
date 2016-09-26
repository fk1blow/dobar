defmodule Dobar.Responder do
  @moduledoc """
  Dobar Responder

  Its a role that a module can have in order to become a responder in the
  chain of a conversation.

  ## handling messages

  In otder to handle messages, a module that uses the `Dobar.Responder`, will
  have to declare the `on/2` macro to define the callback.
  The first argument received by this "do: block" will be the name of the
  intent that has been evaluated(eg: :send_message, :say_time, :create_alarm),
  and the second is the `data` map which carries various data about the intent,
  usually features and the intent itself.
  """

  alias Dobar.Reaction

  defmacro __using__(_opts) do
    quote do
      use GenServer
      import Dobar.Responder

      @before_compile Dobar.Responder



      # not shure if this has any impact, here
      # var!(reply) = &__MODULE__.output/2

      def start_link(opts) do
        GenServer.start_link __MODULE__, [interface: opts[:interface]]
      end

      def init(args) do
        {:ok, %{interface: args[:interface]}}
      end

      def handle_cast(message, state) do
        IO.puts ":message: #{inspect message}"
        # IO.inspect Module.__info__ :module
        respond_to(message, state.interface)
        {:noreply, state}
      end

      def respond_to(_, _), do: :ok

      defoverridable [respond_to: 2]

      @doc """
      Will output the message to the inter
      """
      def reply(interface, {type, message}) do
        apply interface, :output, [type, message]
      end
    end
  end

  # add the "catch all" handler before adding the users responders handlers
  defmacro __before_compile__(_env) do
    quote do
      def handle_cast(message, state), do: {:noreply, state}
      def respond_to(_, _), do: :ok
    end
  end

  @doc """
  Will add an action withing responder's chain. The action is a `[do: block]`
  """
  defmacro on(about, data, do: do_block) do
    IO.puts "ondatablock______ : #{inspect data}"
    quote do
      def respond_to({unquote(about), unquote(data)}, var!(interface)),
        do: unquote(do_block)
    end
  end
  # defmacro hear(%Reaction{} = reaction, do: block) do
  # defmacro about(%Reaction{} = reaction, do: block) do
  defmacro on(reaction, do: block) do
    IO.puts "reactionblock______ : #{inspect reaction}"
    quote do
      def respond_to(unquote(reaction), var!(interface)),
        do: unquote(block)
    end
  end
end
