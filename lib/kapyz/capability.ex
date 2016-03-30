defmodule Dobar.Kapyz.Capability do
  @moduledoc """
  Protocol for handling intention capabilities.
  It defines the generic features like start/init and handle_info giving the
  implementation module the posibility to `react` when dobar has evaluated
  a new Intent expression structure.
  """

  alias Dobar.Kapyz.Error.InvalidCapabilityName

  @callback react(Map.t) :: any

  defmacro __using__(opts) do
    quote do
      use GenServer

      alias Dobar.Model.Intent

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
      def handle_info({:handle_capability, intent}, _) do
        react intent
        {:noreply, nil}
      end
    end
  end
end
