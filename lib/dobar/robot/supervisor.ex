defmodule Dobar.Robot.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def start_robot(sup, robot_conf) do
    Supervisor.start_child sup, [robot_conf]
  end

  def shutdown_robot(sup, pid) do
    Supervisor.terminate_child(sup, pid)
  end

  def init(_) do
    children = [
      worker(Dobar.Robot, [], restart: :transient)
    ]
    supervise children, strategy: :simple_one_for_one
  end
end
