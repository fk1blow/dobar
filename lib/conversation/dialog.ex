defmodule Dobar.Conversation.Dialog do
  use GenServer

  alias Dobar.Model.Intent
  alias Dobar.Conversation.Intention.Provider, as: IntentionProvider
  alias Dobar.Conversation.Topic

  # interface
  #

  def start_link(intent) do
    GenServer.start_link(__MODULE__, [intent: intent])
  end

  @doc """
  Used only after the initialization of the Dialog(which prefills the topics, with
  the given intent), this function will return the next possible topic.
  """
  def next_topic(pid) do
    GenServer.call pid, :next_topic
  end

  @doc """
  Will complete the next possible topic and return the next topic if any left.
  """
  def react(pid, %Intent{} = intent) do
    GenServer.call pid, {:react, intent}
  end

  def fill_topics(topics) do
    #
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
      {:ok, topic}         -> {:topic, Topic.question(topic.pid)}
      {:completed, topics} -> {:completed, %{intent: state.intent, topics: topics}}
    end
    {:reply, answer, state}
  end

  def handle_call({:react, intent}, _from, %{topics: dialog_topics} = state) do
    completed = with {:ok, expected} <- next_expected_topic(dialog_topics),
                     {:ok, topic}    <- complete_topic(expected, intent),
                     {:ok, value}    <- Topic.complete(topic.pid, intent),
                do:  {:ok, value}

    next_expected = case completed do
      {:ok, value} -> next_expected_topic(dialog_topics)
      other        -> other
    end

    answer = case next_expected do
      {:ok, topic}         -> {:topic, Topic.question(topic.pid)}
      {:completed, topics} -> {:completed, %{intent: state.intent, topics: topics}}
      {:nomatch, reason}   -> {:nomatch, reason}
    end

    {:reply, answer, state}
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
    {:ok, intent_def} = IntentionProvider.intention(intent_name)
    entity_slots = only_entities(intent_def[intent_name])
  end

  defp create_topic(capability, intent_entities) do
    {:ok, topic} = Topic.start_link(elem(capability, 1), intent_entities)
    %{name: elem(capability, 0), pid: topic}
  end

  defp next_expected_topic(topics) do
    case incompleted_topics(topics) |> List.first do
      nil -> {:completed, topics_list(topics)}
      topic -> {:ok, topic}
    end
  end

  defp complete_topic(topic, intent) do
    case Topic.complete?(topic.pid, intent) do
      {:match, _entities}       -> {:ok, topic}
      {:nomatch, key, entities} -> {:nomatch, "no match for key #{key}"}
    end
  end

  # TODO: must return a %Topic{} struct, to better understand the entities involved
  defp topics_list(topics) do
    topics
    |> Enum.map(&(Topic.structure &1.pid))
    |> Enum.map(&(elem(&1, 1)))
    |> List.foldl(%{}, &(Map.put(&2, String.to_atom(&1.name), &1.value)))
  end

  defp only_entities(capabilities) do
    capabilities
    |> Enum.filter(fn(x) -> is_nil(elem(x, 1)[:entity]) == false end)
    |> Enum.map(fn(x) -> {elem(x, 0), Enum.into(elem(x, 1), %{})} end)
  end
end
