defmodule Dobar.Conversation.Manager do
  use GenServer

  alias Dobar.Model.Conversation
  alias Dobar.Model.Intent

  @name __MODULE__

  def start_link do
    GenServer.start_link @name, [], name: @name
  end

  def init(_) do
    # {:ok, %Conversation{......}} is the alternate state for
    # when a conversation is taking place; also, can easily be checked for
    # times when you need to know if a conversation is active or not.
    {:ok, nil}
  end

  #
  # interface

  def evaluate_intent(%Intent{} = intent) do
    GenServer.call @name, {:eval_intent, intent}
  end

  #
  # callbacks

  def handle_call({:eval_intent, intent}, _from, state) do
    {:noreply, state}
  end
end
