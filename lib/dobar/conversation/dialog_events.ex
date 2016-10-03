defmodule Dobar.Conversation.DialogEvents do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, []
  end

  def get_child(sup, child_id) do
      sup
      |> Supervisor.which_children
      |> Enum.find(nil, fn x -> elem(x, 0) == child_id end)
  end

  def init(_) do
    children = [
      worker(GenEvent, [], id: :dialog_event_mananger)
    ]
    supervise(children, strategy: :one_for_one)
  end
end
