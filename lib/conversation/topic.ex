defmodule Dobar.Conversation.Topic do
  use GenServer

  alias Dobar.Model.Intent
  alias Dobar.Conversation.Intention.Provider, as: IntentionProvider
  alias Dobar.Conversation.Capability

  @doc """
  Starts a new Topic that represents the given `Dobar.Modal.Intent`
  """
  def start_link(%Intent{} = intent) do
    GenServer.start_link(__MODULE__, [intent: intent])
  end

  @doc """
  Used only after the initialization of the Dialog(which prefills the topics, with
  the given intent), this function will return the next possible subject capability.
  """
  # def continue(pid), do: GenServer.call pid, :next_topic
  def react(pid), do: GenServer.call pid, :next_topic

  @doc """
  Will complete the next possible topic and return the next subject capability
  if any left.
  """
  def react(pid, %Intent{} = intent), do: GenServer.call pid, {:react, intent}

  @doc """
  TODO: this function does not have a clear meaning; it doesn;t really give away
  the effect that it has on the Topic itself nor the expression it computes/returns.

  TODO: rename this function or remove it completely from the `Topic` module

  Finds an alternate topic within this intent's capabilities
  """
  def alternative(pid, intent), do: GenServer.call pid, {:alternative_topic, intent}

  @doc """
  Fills the topics entities by the provided `entities` parameter
  """
  def fill_topics(pid, entities), do: GenServer.cast pid, {:fill_topics, entities}

  # callbacks
  #

  def init(args) do
    intent = args[:intent]
    capabilities = available_capabilities(intent)
    |> Enum.filter(&(is_tuple(&1)))
    |> Enum.map(&(create_topic(&1, intent.entities)))
    {:ok, %{intent: intent, capabilities: capabilities}}
  end

  def handle_call(:next_topic, _from, state) do
    answer = case next_expected_topic(state.capabilities) do
      {:ok, capability} ->
        {:topic, Capability.question(capability.pid)}
      {:completed, capabilities} ->
        {:completed, %{intent: state.intent, capabilities: capabilities}}
    end
    {:reply, answer, state}
  end

  def handle_call({:react, intent}, _from, state) do
    topic_status =
      with {:ok, expected}   <- next_expected_topic(state.capabilities),
           {:ok, capability} <- complete_topic(expected, intent),
           {:ok, value}      <- Capability.complete(capability.pid, intent),
      do:  next_expected_topic(state.capabilities)

    answer = case topic_status do
      {:ok, capability}    -> {:next, Capability.outcome(capability.pid)}
      {:completed, topics} -> {:completed, %{intent: state.intent, topics: topics}}
      {:nomatch, reason}   -> {:nomatch, reason}
    end

    {:reply, answer, state}
  end

  def handle_call({:alternative_topic, alt_intent}, _from, %{intent: intent} = state) do
    # search for a reference inside the current intent
    reference = with {:ok, list}        <- reference_capabilities(intent),
                     {:ok, capability}  <- intent_has_capability(alt_intent, list),
                 do: {:ok, capability}
    # if internal reference was found, return it, else, search for a
    # reference in the global context of the intention provider
    answer = case reference do
      {:ok, capability} ->
        {:internal, capability}
      {:error, _reason} ->
        case IntentionProvider.normal_intention(String.to_atom alt_intent.name) do
          {:ok, capability} -> {:external, capability}
          {:error, reason} -> {:error, reason}
        end
    end
    {:reply, answer, state}
  end

  def handle_cast({:fill_topics, entities}, %{capabilities: capabilities} = state) do
    Enum.map(capabilities, fn(capability) ->
      Capability.complete(capability.pid, entities)
    end)
    {:noreply, state}
  end

  # private
  #

  # TODO: try to remove this utility functions; can it be moved to a Capability utils?!

  # TODO: rename to `incompleted_capabilities`
  defp incompleted_topics(capabilities) do
    capabilities
    |> Enum.map(&(%{capability: &1, completed: Capability.completed?(&1.pid)}))
    |> Enum.filter(fn(topic) -> topic.completed == false end)
    |> Enum.sort(&(
      Capability.priority(&1.capability.pid) < Capability.priority(&2.capability.pid)))
    |> Enum.map(&(&1.capability))
  end

  # TODO: watch out for when there is no intention defined for the input intent
  defp available_capabilities(%Intent{} = intent) do
    intent_name = String.to_atom(intent.name)
    {:ok, intent_def} = IntentionProvider.normal_intention(intent_name)
    filter_capabilities(intent_def[intent_name], :entity)
  end

  defp reference_capabilities(%Intent{} = intent) do
    intent_name = String.to_atom(intent.name)
    {:ok, intent_def} = IntentionProvider.meta_intention(intent_name)
    case filter_capabilities(intent_def[intent_name], :reference) do
      [h|t] -> {:ok, [h|t]}
      _     -> {:error, "no reference capabilities found"}
    end
  end

  # TODO: rename to `create_capability`
  defp create_topic(capability, intent_entities) do
    {:ok, new_capability} = Capability.start_link(elem(capability, 1), intent_entities)
    %{name: elem(capability, 0), pid: new_capability}
  end

  # TODO: rename to `next_expected_capability`
  defp next_expected_topic(capabilities) do
    case capabilities |> incompleted_topics |> List.first do
      nil -> {:completed, topics_list(capabilities)}
      capability -> {:ok, capability}
    end
  end

  defp complete_topic(capability, intent) do
    case Capability.complete?(capability.pid, intent) do
      {:match, _key, _entities} -> {:ok, capability}
      {:nomatch, key, entities} -> {:nomatch, "no match for key #{key}"}
    end
  end

  # TODO: must return a %Topic{} struct, to better understand the entities involved
  defp topics_list(capabilities) do
    capabilities
    |> Enum.map(&(Capability.structure &1.pid))
    |> Enum.map(&(elem(&1, 1)))
    |> List.foldl(%{}, &(Map.put(&2, String.to_atom(&1.name), [%{value: &1.value}])))
  end

  defp filter_capabilities(capabilities, by_field) do
    capabilities
    |> Enum.filter(fn(x) -> is_nil(elem(x, 1)[by_field]) == false end)
    |> Enum.map(fn(x) -> {elem(x, 0), Enum.into(elem(x, 1), %{})} end)
  end

  defp intent_has_capability(%Intent{name: name}, capabilities) do
    case Enum.find(capabilities, &(elem(&1, 0) == String.to_atom(name))) do
      nil        -> {:error, "no capability found"}
      capability -> {:ok, capability}
    end
  end
end
