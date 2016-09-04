defmodule Dobar.Conversation.Supervisor do
  use Supervisor

  # TBD
  def start_link(opts) do
    Supervisor.start_link __MODULE__, [input_events: opts[:input_events_manager]], name: __MODULE__
  end

  # TBD
  def init(args) do
    children = [
      worker(Dobar.Conversation, [[input_events: args[:input_events]]])
    ]
    supervise(children, strategy: :one_for_one)
  end
end
