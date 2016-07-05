# The Dialog should contain a reference for each slot - so a Topic for each
# slot that has to be filled
defmodule Dobar.Conversation.Dialog do
  use GenServer

  alias Dobar.Model.Intent
  alias Dobar.Conversation.Slot
  alias Dobar.Conversation.Intention.Provider, as: IntentionProvider
  alias Dobar.Conversation.Topic

  # interface
  #

  def start_link(name, intent) do
    GenServer.start_link(
      __MODULE__, [intent: intent], name: name)
  end

  def next_topic(pid) do
    GenServer.call pid, :next_topic
  end

  def react(pid, %Intent{} = intent) do
    GenServer.call pid, {:intent_reaction, intent}
  end

  # callbacks
  #

  def init(args) do
    intent = args[:intent]
    topics = available_capabilities(intent)
    |> Enum.filter(&(is_tuple(&1)))
    |> Enum.map(&(create_topic(&1, intent.entities)))
    {:ok, %{intent: intent, topics: topics}}
  end

  def handle_call(:next_topic, _from, state) do
    topic = incompleted_topics(state.topics) |> List.first
    answer = case topic do
      nil -> {:completed, "all topics completed"}
      topic -> {:topic, Topic.question(topic.pid)}
    end
    {:reply, answer, state}
  end

  def handle_call({:intent_reaction, intent}, _from, state) do
    {:noreply, nil, state}
  end

  # private
  #

  defp incompleted_topics(topics) do
    Enum.map(topics, &(%{topic: &1, completed: Topic.completed?(&1.pid)}))
    |> Enum.filter(fn(topic) -> topic.completed == false end)
    |> Enum.sort(&(Topic.priority(&1.topic.pid) < Topic.priority(&2.topic.pid)))
    |> Enum.map(&(&1.topic))
  end

  defp available_capabilities(%Intent{} = intent) do
    intent_name = String.to_atom(intent.name)
    intent_def = IntentionProvider.intention(intent_name)
    entity_slots = Slot.only_entities(intent_def[intent_name])
  end

  defp create_topic(capability, intent_entities) do
    {:ok, pid} = Topic.start_link(elem(capability, 1), intent_entities)
    %{name: elem(capability, 0), pid: pid}
  end
end
