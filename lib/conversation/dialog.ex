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

  @doc """
  Will return the next possible topic by filtering the completed ones and
  then sorting them by priority. Finally, it takes the first element from the list
  which has to be the next topic.
  """
  def next_topic(pid) do
    GenServer.call pid, :next_topic
  end

  def react(pid, %Intent{} = intent) do
    GenServer.call pid, {:react, intent}
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
    answer = case next_expected_topic(state.topics) do
      nil -> {:completed, "all topics completed"}
      topic -> {:topic, Topic.question(topic.pid)}
    end
    {:reply, answer, state}
  end

  def handle_call({:react, intent}, _from, state) do
    # get the next expected topic

    # next_topic = case next_expected_topic(state.topics) do
    #   nil -> {:completed, "all topics completed"}
    #   topic -> {:topic, Topic.question(topic.pid)}
    # end

    next_expected = next_expected_topic(state.topics)

    # has_completed = case complete_topic?(next_expected, intent) do
    #   nil -> IO.puts "cannot "
    # end

    # ask if the topic can be completed
    # and if it can, complete it
    with {:ok, topic} <- complete_topic?(next_expected, intent),
         {:ok, value} <- Topic.complete(topic.pid)


    # IO.puts "next_topic: #{inspect next_topic}"

    # Topic.complete(next_topic)

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

  defp next_expected_topic(topics) do
    incompleted_topics(topics) |> List.first
  end

  # this function should return a {:ok, topic}
  defp complete_topic?(nil, _intent), do: false
  defp complete_topic?(topic, intent) do
    Topic.complete? topic.pid, intent
  end
end
