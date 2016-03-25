defmodule Dobar.Intent.Supervisor do
  use Supervisor

  alias Dobar.Intent.IntentHandler

  @intent_event_manager Dobar.Intent.EventManager

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    children = [
      worker(GenEvent, [[name: @intent_event_manager]], []),
      worker(Dobar.Intent.State, [])
    ]
    opts = [strategy: :one_for_one]

    IntentHandler.register_with_manager(@intent_event_manager)

    # with {:ok, spec} <- supervise(children, opts),
    #   :ok <- IntentHandler.register_with_manager(@intent_event_manager),
    #   do: {:ok, spec}

    supervise(children, opts)
  end
end
