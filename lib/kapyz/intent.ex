defmodule Dobar.Kapyz.Intent do
  defmacro __using__(opts) do
    quote do
      use GenServer
      @name unquote(opts[:name])

      def start_link do
        GenServer.start_link __MODULE__, []
      end

      def init(_) do
        Dobar.Kapyz.Dispatcher.register_intent @name, self
        {:ok, nil}
      end

      def handle_info(:test, state) do
        IO.puts "handling :test"
        {:noreply, state}
      end
    end
  end
end
