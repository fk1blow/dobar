defmodule Dobar.Robot do
  @type t :: %__MODULE__{
    pid: pid | atom,
    responders: []
  }

  defstruct pid: nil,
     responders: []

  use GenServer

  def start_link(conf) do
    GenServer.start_link __MODULE__, conf
  end

  def new(robot_config) do
    Dobar.Robot.Supervisor.start_child(Dobar.Robot.Supervisor, robot_config)
  end

  def init(conf) do
    {:ok, %{adapter: conf[:adapter],
            responders: conf[:effects],
            conversation: conf[:conversation],
            evaluator: conf[:evaluator]}}
  end
end
