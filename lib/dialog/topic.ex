defmodule Dobar.Dialog.Topic do
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

  You don't really (need to) know how the Topic does its job, other than a standard
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

  alias Dobar.Model.Reaction
  alias Dobar.Model.Intent
  alias Dobar.Dialog.Capability
  alias Dobar.Conversation.Intention.Provider, as: IntentionProvider

  @doc """
  Starts a new Topic that represents the given `Dobar.Modal.Intent` while
  prefilling the capabilities with the %Intent

  Starts a new Topic with a strict set of capabilities handed over by the caller.
  The topic's capabilities will be constructued manually, added to the provided intent.
  """
  def start_link(%Intent{} = intent) do
    GenServer.start_link(__MODULE__, intent)
  end
  def start_link(%Intent{} = intent, capabilities) do
    GenServer.start_link(__MODULE__, [intent: intent, capabilities: capabilities])
  end

  @doc """
  Reacts with the current state of the Topic

  Will complete the next possible topic and return the next subject capability
  if any left.

  Will complete for each and every entity inside the entities list and return the
  next subject capability if any left.
  """

  # TODO: rename to Topic.advance/1 and Topic.advance/2

  def react(pid), do: GenServer.call pid, {:react, nil}
  def react(pid, %Intent{} = intent), do: GenServer.call pid, {:react, intent}
  def react(pid, %{} = entities), do: GenServer.call pid, {:react, entities}

  @doc """
  Will return the Topic's current intent
  """
  def intent(pid), do: GenServer.call pid, :get_intent

  @doc """
  Gets the representation of all the capabilities of the current topic.
  """
  def capabilities(pid), do: GenServer.call pid, :get_capabilities

  # callbacks
  # ---------

  def init(%Intent{} = intent) do
    capabilities =
      available_capabilities(intent)
      |> Enum.filter(&(is_tuple(&1)))
      |> Enum.map(&(create_capability(&1, intent)))
      |> validate_capabilities(intent)
  end
  def init([intent: %Intent{} = intent, capabilities: capabilities]) do
    capabilities
    |> Enum.map(&({elem(&1, 0), elem(&1, 1)}))
    |> Enum.map(&(create_capability(&1, intent)))
    |> validate_capabilities(intent)
  end

  def handle_call({:react, nil}, _from, state) do
    answer = case next_capability(state.capabilities) do
      {:ok, capability} ->
        %Reaction{type: :question,
                  intent: state.intent,
                  features: Capability.outcome(capability.pid)}
      {:completed, capabilities} ->
        %Reaction{type: :completed,
                  intent: state.intent,
                  features: capabilities}
    end

    {:reply, answer, state}
  end
  def handle_call({:react, %Intent{name: "carrier_bearer"} = intent}, _from, state) do
    # takes each capability, test it for compability againts the intent,
    # filters out `:input` capabilities and `:nomatches` then takes the compatible
    # ones and compleste them
    state.capabilities
    |> Stream.map(&(%{cpid: &1.pid, compat: Capability.compatibility(&1.pid, intent)}))
    |> Stream.filter(&(elem(&1.compat, 1) != :input))
    |> Stream.filter(&(elem(&1.compat, 0) != :nomatch))
    |> Stream.each(&(Capability.complete(&1.cpid, intent)))
    |> Stream.run

    answer = case next_capability(state.capabilities) do
      {:ok, capability} ->
        %Reaction{type: :question,
                  intent: state.intent,
                  features: Capability.outcome(capability.pid)}
      {:completed, capabilities} ->
        %Reaction{type: :completed,
                  intent: state.intent,
                  features: capabilities}
    end

    {:reply, answer, state}
  end
  def handle_call({:react, %Intent{} = intent}, _from, state) do
    # takes the next capability, tests it for compability match and if compatible,
    # completes it with the intent and asks for the next capability of the topic
    topic_status =
      with {:ok, expected}   <- next_capability(state.capabilities),
           {:ok, capability} <- capability_match(expected, intent),
           {:ok, value}      <- Capability.complete(capability.pid, intent),
      do:  next_capability(state.capabilities)

    answer = case topic_status do
      {:ok, capability} ->
        %Reaction{type: :question,
                  intent: state.intent,
                  features: Capability.outcome(capability.pid)}
      {:completed, topics} ->
        %Reaction{type: :completed,
                  intent: state.intent,
                  features: topics}
      {:nomatch, reason} ->
        %Reaction{type: :nomatch,
                  intent: state.intent,
                  features: %{reason: reason}}
    end

    {:reply, answer, state}
  end
  def handle_call(:get_intent, _from, state) do
    {:reply, state.intent, state}
  end
  def handle_call(:get_capabilities, _from, state) do
    capabilities =
      state.capabilities
      |> Enum.map(&(Capability.structure &1.pid))
      |> Enum.map(&(elem &1, 1))
    {:reply, capabilities, state}
  end

  # private
  #

  defp incompleted_topics(capabilities) do
    capabilities
    |> Enum.map(&(%{capability: &1, completed: Capability.completed?(&1.pid)}))
    |> Enum.filter(&(&1[:completed] == false))
    |> Enum.sort(
      &(Capability.priority(&1.capability.pid) < Capability.priority(&2.capability.pid)))
    |> Enum.map(&(&1.capability))
  end

  # TODO: watch out for when there is no intention defined for the input intent
  defp available_capabilities(%Intent{} = intent) do
    intent_name = String.to_atom(intent.name)
    intention = IntentionProvider.intention(intent_name)

    IO.puts "intention: #{inspect intention}"

    case intention do
      {:ok, intent_def} -> filter_capabilities(intent_def[intent_name])
      {:error, reason} -> []
    end
  end

  defp create_capability(capability, intent) do
    {:ok, new_capability} = Capability.start_link(capability, intent)
    %{name: elem(capability, 0), pid: new_capability}
  end

  defp next_capability(capabilities) do
    case capabilities |> incompleted_topics |> List.first do
      nil ->
        completed = capabilities
        |> Enum.map(&(Capability.structure &1.pid))
        |> Enum.map(&(elem &1, 1))
        {:completed, completed}
      capability ->
        {:ok, capability}
    end
  end

  defp capability_match(capability, intent) do
    case Capability.compatibility(capability.pid, intent) do
      {:match, _key, _entities} -> {:ok, capability}
      {:nomatch, key, entities} -> {:nomatch, "no match for key #{inspect key}"}
    end
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
