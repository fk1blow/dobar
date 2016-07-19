defmodule Dobar.Conversation.Topic do
  @moduledoc """

  Conversation Topic
  ==================

  It represents the (main)Topic of a dialog/conversation. It has a dynamic state
  that is modeled through time, defined by the Capabilities it ownes and their need
  for input(usually represented by an %Intent).

  ## lifecycle

  Its lifecycle is modeled just by reacting to the Dialog
  (calling `Topic.react/1` or `Topic.react/2`).
  Reacting to no Intent(`Topic.react/1`), the Topic doesn't change its state.
  Calling with an Intent using `Topic.react/2` function, it feeds the intent to
  all its capabilities, make them react in turn.

  Note that it should be protected of infinite topics that never end; it needs
  a clear start and end, possibly adding a timeout...

  ## Public Interface

  `start_link/1`

  `react/1`

  `react/2`

  ## Separation refactor

  By removing the `alternate/2` and `fill_topics` and replacing them with the generic
  `react/1` or `react/2`, you get the benefit of better separation and encapsulation.

  #### better separation

  Removing the `alternative/2` you separate the part where a Dialog decides which
  action to take based on the reaction of a Topic.

  #### encapsulation

  You don;t really (need to)know how the Topic does its job, other than a standard
  generic contract - it reacts(using `react/1`, `react/2`) to the Dialog and to
  intentions, advancing in its state as it uses differrent capabilities and filling
  their needs for input(slots).

  ## topic reaction

  The reaction of a topic(calling `Topic.react/1` or `Topic.react/2`) is the
  side-effect that the topic is expressing. It modified its internal state and
  always gives a reaction when invoked.

  The reaction makes the case of a simpler Dialog, where you have multiple
  paths/routes where a Dialog might chose. The chosing strategy is by pattern
  matching and then delegating to every reaction used by the Dialog.
  """

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
  def react(pid), do: GenServer.call pid, :react

  @doc """
  Will complete the next possible topic and return the next subject capability
  if any left.
  """
  def react(pid, %Intent{} = intent), do: GenServer.call pid, {:react, intent}

  @doc """
  Will complete for each and every entity inside the entities list and return the
  next subject capability if any left.
  """
  def react(pid, [h|t] = entities), do: GenServer.call pid, {:react, entities}

  @doc """
  Will return the Topic's current intent
  """
  def intent(pid), do: GenServer.call pid, :get_intent

  # callbacks
  #

  # stop the dialog if there are no capabilities for the intent that was passed
  def init(args) do
    intent = args[:intent]
    capabilities = available_capabilities(intent)
    |> Enum.filter(&(is_tuple(&1)))
    |> Enum.map(&(create_topic(&1, intent.entities)))
    |> validate_capabilities(intent)
  end

  def handle_call(:react, _from, state) do
    answer = case next_expected_topic(state.capabilities) do
      {:ok, capability} ->
        {:topic, Capability.outcome(capability.pid)}
      {:completed, capabilities} ->
        {:completed, %{intent: state.intent, capabilities: capabilities}}
    end
    {:reply, answer, state}
  end

  def handle_call({:react, %Intent{} = intent}, _from, state) do
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

  def handle_call({:react, [h|t]}, _from, state) do
    IO.puts "should fill the capabilities features with the provided list"
    {:reply, nil, state}
  end

  def handle_call(:get_intent, _from, state) do
    {:reply, state.intent, state}
  end

  # private
  #

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
    case IntentionProvider.intention(intent_name) do
      {:ok, intent_def} -> filter_capabilities(intent_def[intent_name])
      {:error, reason} -> []
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
    |> List.foldl(%{}, &(Map.put(&2, &1.name, &1.value)))
  end

  defp filter_capabilities(capabilities) do
    capabilities
    |> Enum.filter(&(elem(&1, 0) != :relationship))
    |> Enum.filter(&(is_nil(elem(&1, 1)[:entity]) == false))
    |> Enum.map(fn(x) -> {elem(x, 0), Enum.into(elem(x, 1), %{})} end)
  end

  defp validate_capabilities([], intent) do
    {:stop, {"cannot start topic without capabilities", intent}}
  end
  defp validate_capabilities([h|t] = capabilities, intent) do
    {:ok, %{intent: intent, capabilities: capabilities}}
  end
end
