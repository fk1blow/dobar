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

  defmacro __using__(_opts) do
    quote do
      use GenServer
      import Dobar.Responder

      @before_compile Dobar.Responder

      def start_link(opts) do
        GenServer.start_link __MODULE__, []
      end
    end
  end

  # add the "catch all" handler before adding the users responders handlers
  defmacro __before_compile__(_env) do
    quote do
      def handle_cast(message, state), do: {:noreply, state}
    end
  end

  @doc """
  Will add an action withing responder's chain. The action is a `[do: block]`
  """
  defmacro on(about, data_block, do: do_block) do
    quote do
      def handle_cast({unquote(about), unquote(data_block[:data])}, _state) do
        unquote(do_block)
        {:noreply, nil}
      end
    end
  end
end
