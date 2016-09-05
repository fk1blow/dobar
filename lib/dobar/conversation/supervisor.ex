defmodule Dobar.Conversation.Supervisor do
  use Supervisor

  # TBD
  def start_link(opts) do
    Supervisor.start_link __MODULE__, opts, name: __MODULE__
  end

  # TBD
  def init(args) do
    children = [
      worker(Dobar.Conversation, [
        [input_events_manager: args[:input_events_manager],
         dialog_events_manager: args[:dialog_events_manager]]])
    ]
    supervise(children, strategy: :one_for_one)
  end
end
