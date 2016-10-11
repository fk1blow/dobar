defmodule Dobar.Robot.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def start_child(pid, robot_conf) do
    Supervisor.start_child pid, [robot_conf]
  end

  def init(_) do
    children = [
      worker(Dobar.Robot, [])
    ]
    supervise children, strategy: :simple_one_for_one
  end
end
