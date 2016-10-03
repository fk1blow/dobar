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

  ## future improvements

  In the near future, if the `on` macro/handler won't suffice, you can add more
  granular handler for different types of behaviours like when dobar asks a
  question, it canceled a dialog or couldn't find an intention.

    hear ~r"kaboom" do
      IO.puts "dobar heared this type of message from the user so you can..."
    end

    respond topic: :time do
      IO.puts "dobar just asked you about this topic - `:time`"
    end

    react :dialog_cancel, data: %{} do
      IO.puts "dobar has canceled the dialog so you can to whatever you want"
    end
  """

  alias Dobar.Reaction

  defmacro __using__(_opts) do
    quote do
      use GenServer
      import Dobar.Responder
      alias Dobar.Reaction

      @before_compile Dobar.Responder

      def start_link(opts) do
        GenServer.start_link __MODULE__, [interface: opts[:interface]]
      end

      def init(args) do
        {:ok, %{interface: args[:interface]}}
      end

      def handle_cast(message, state) do
        respond_to(message, state.interface)
        {:noreply, state}
      end

      def respond_to(_, _), do: :ok

      defoverridable [respond_to: 2]

      @doc """
      Will output the message to the interface
      """
      def reply(interface, {type, message}) do
        apply interface, :output, [type, message]
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      # catch all `respond_to` s that don't match
      def respond_to(_, _), do: :ok
    end
  end

  @doc """
  Will add an action withing responder's chain. The action is a `[do: block]`
  """
  defmacro on(reaction, do: block) do
    quote do
      def respond_to(unquote(reaction), var!(interface)),
        do: unquote(block)
    end
  end
end
