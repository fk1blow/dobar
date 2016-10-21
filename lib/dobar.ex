defmodule Dobar do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      # start the robot's supervisor
      supervisor(Dobar.Robot.Supervisor, []),
      # start the effector runner task supervisor
      supervisor(Task.Supervisor, [[name: Dobar.Effect.Task]]),
      # start the effector runner
      worker(Dobar.Effect.Runner, [[name: Dobar.Effect.Runner]]),
      # start the robot registry
      worker(Dobar.Robot.Registry, [])
    ]

    opts = [strategy: :one_for_one, name: Dobar.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
