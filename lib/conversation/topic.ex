# There should be another abstract over the topic, which is the Dialog
# The Dialog should represent the session in which a conversation or more,
# will take place. The Dialog has some topics to fill and the Conversation
# will contain one or many Dialogs!
defmodule Dobar.Conversation.Topic do
  use GenServer

  alias Dobar.Model.Intent

  def start_link(capability, entities) do
    GenServer.start_link __MODULE__, [capability: capability, prefill: entities]
  end

  def completed?(pid) do
    GenServer.call(pid, :is_completed)
  end

  def priority(pid) do
    GenServer.call(pid, :get_priority)
  end

  def question(pid) do
    GenServer.call(pid, :get_question)
  end

  def complete?(pid, intent) do
    GenServer.call(pid, {:can_complete, intent})
  end

  def complete(pid, value) do
    GenServer.call(pid, {:complete, value})
  end

  # callbacks
  #

  def init(args) do
    {:ok, %{capability: args[:capability],
            value: prefill_value(args[:prefill], args[:capability]),
            created_on: nil}}
  end

  def handle_call(:is_completed, _from, state) do
    is_completed = is_nil(state.value) == false
    {:reply, is_completed, state}
  end

  def handle_call(:get_priority, _from, state) do
    {:reply, state.capability.prio, state}
  end

  def handle_call(:get_question, _from, state) do
    # TODO: change hardcoded question, when ready
    question = "question is: #{state.capability.entity}"
    {:reply, question, state}
  end

  def handle_call({:can_complete, intent}, _from, state) do
    key = String.to_atom state.capability.entity
    match = intent.entities[key]
    reply = case match do
      nil -> {:nomatch, key, intent.entities}
      [h|t] -> {:match, h}
    end
    {:reply, reply, state}
  end

  def handle_call({:complete, intent}, _from, state) do
    key = String.to_atom state.capability.entity
    match = intent.entities[key] |> List.first
    {:reply, {:ok, match.value}, Map.merge(state, %{value: match.value})}
  end

  # private
  #

  defp prefill_value(prefill, capability) do
    entity = String.to_atom capability.entity
    case prefill[entity] do
      nil -> nil
      entity -> List.first(entity).value
    end
  end
end
