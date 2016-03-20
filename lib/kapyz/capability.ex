defmodule Dobar.Kapyz.Capability do
  @callback react_intention(Map.t) :: any

  defmacro __using__(opts) do
    quote do
      use GenServer
      alias Dobar.Kapyz.Intent

      @behaviour Dobar.Kapyz.Capability
      @name unquote(opts[:name])

      def start_link do
        GenServer.start_link __MODULE__, []
      end

      def init(_) do
        Dobar.Kapyz.Dispatcher.register_intent @name, self
        {:ok, nil}
      end

      def handle_info({:test, data}, state) do
        react_intention %Intent{text: data}
        {:noreply, state}
      end
    end
  end
end
