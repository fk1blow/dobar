defmodule Dobar.Kapyz.Capability do
  @moduledoc """
  Should unregister the intent from the Dispatcher, although
  not necesarely, because the Dispatcher, automagically replaces the
  leftovers, and attaches the same process, registered with the sama name, etc
  """

  alias Dobar.Kapyz.Error.InvalidCapabilityName

  # the cability can react to an intention?
  @callback react(Map.t) :: any

  defmacro __using__(opts) do
    quote do
      use GenServer

      alias Dobar.Models.Intent

      @behaviour Dobar.Kapyz.Capability
      @name unquote(opts[:name] || raise InvalidCapabilityName)

      def start_link do
        GenServer.start_link __MODULE__, []
      end

      def init(_) do
        # no need to unregister the handler - the capability callback module will
        # always restart and override the previous(dead) registration entry
        Dobar.Kapyz.Dispatcher.register_capability @name, self
        {:ok, nil}
      end

      @doc """
      Handles the capability and calls the `react_intention/1` function
      on the callback module, eg: `Dobar.Kapyz.Capability.SendMessage`
      """
      def handle_info({:handle_capability, intent}, state) do
        react intent
        {:noreply, state}
      end
    end
  end
end
