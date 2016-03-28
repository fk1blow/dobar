defmodule Dobar.Intent.Supervisor do
  use Supervisor

  # @intent_event_manager Dobar.Intent.EventManager
  @intent_event_manager :xrx

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    children = [
      worker(GenEvent, [[name: @intent_event_manager]]),
      worker(Dobar.Intent.State, []),
      worker(Dobar.Intent.Resolver, [])
    ]
    opts = [strategy: :one_for_one]


    # with {:ok, spec} <- supervise(children, opts),
    #   :ok <- IntentHandler.register_with_manager(@intent_event_manager),
    #   do: {:ok, spec}

    # r = supervise(children, opts)
    # Dobar.Intent.IntentHandler.register_with_manager(@intent_event_manager)
    # r

    supervise(children, opts)
  end
end
