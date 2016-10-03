defmodule Dobar.Robot.Supervisor do
  use Supervisor

  def start_link do
    #
  end

  def start_robot(sup) do
    #
  end

  def init(_) do
    children = []
    supervise children, strategy: :simple_one_for_one
  end
end
