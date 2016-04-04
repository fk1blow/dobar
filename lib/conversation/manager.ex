defmodule Dobar.Conversation.Manager do
  use GenServer

  alias Dobar.Model.Conversation

  @name __MODULE__

  def start_link do
    GenServer.start_link @name, [], name: @name
  end

  def init(_) do
    {:ok, %Conversation{}}
  end
end
