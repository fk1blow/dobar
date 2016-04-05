defmodule Dobar.Conversation.Manager do
  use GenServer

  alias Dobar.Model.Conversation
  alias Dobar.Model.Intent

  @name __MODULE__

  def start_link do
    GenServer.start_link @name, [], name: @name
  end

  def init(_) do
    {:ok, %Conversation{}}
  end

  #
  # interface

  def evaluate_intent(%Intent{} = intent) do
    GenServer.call @name, {:eval_intent, intent}
  end

  #
  # callbacks

  def handle_cast({:eval_intent, intent}, state) do
    {:noreply, state}
  end
end
