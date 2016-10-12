defmodule Dobar.Conversation.Supervisor do
  use Supervisor

  def start_link(opts \\ [name: __MODULE__]) do
    Supervisor.start_link __MODULE__, [], name: opts[:name]
  end

  def start_child(sup, conf) do
    Supervisor.start_child sup, [conf]
  end

  def init(args) do
    children = [
      worker(Dobar.Conversation, [], restart: :transient)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end
