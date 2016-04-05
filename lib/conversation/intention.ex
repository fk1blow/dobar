defmodule Dobar.Conversation.Intention do
  @moduledoc """
  This is the protocol that basically defines an intention which, by itself,
  represents a conversation tree.
  """

  defmacro __using__(_opts) do
    quote do
      use GenServer

      @name __MODULE__

      def start_link(capabilities) do
        GenServer.start_link @name, [capabilities], name: @name
      end

      def init(a) do
        IO.puts "a is: #{inspect a}"
        {:ok, nil}
      end

      # api
      #
    end
  end
end
