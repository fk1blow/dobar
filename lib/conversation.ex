defmodule Dobar.Conversation do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    children = [
      # worker(Dobar.Conversation.Dialog, [:root_dialog]),
      # TODO: in the near future, use the Dialog Provider or something else
      # because even the first root dialog may be a specialized one
      worker(Dobar.Dialog.GenericDialog, [:root_dialog]),
    ]

    supervise children, strategy: :one_for_all
  end
end
