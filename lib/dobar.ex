defmodule Dobar do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Task.Supervisor, [[name: Dobar.Effect.Task]]),
      supervisor(Dobar.Robot.Supervisor, []),

      # volatile
      # supervisor(Dobar.Interface.Supervisor, []),
      # supervisor(Dobar.Conversation.Supervisor, []),

      worker(Dobar.Effect.Runner, [[name: Dobar.Effect.Runner]])
    ]

    opts = [strategy: :one_for_one, name: Dobar.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
