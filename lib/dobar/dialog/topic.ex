defmodule Dobar.Dialog.Topic do
  @moduledoc """
  Dobar Dialog Topic

  It represents the (main)Topic of a dialog/conversation. It has a dynamic state
  that is modeled through time, defined by the Capabilities it ownes and their need
  for input(usually represented by an %Intent).

  ## lifecycle

  Its lifecycle is modeled just by reacting to the Dialog
  (calling `Topic.forward/1` or `Topic.forward/2`).
  Reacting to no Intent(`Topic.forward/1`), the Topic doesn't change its state.
  Calling with an Intent using `Topic.forward/2` function, it feeds the intent to
  all its capabilities, make them react in turn.

  Note that it should be protected of infinite topics that never end; it needs
  a clear start and end, possibly adding a timeout...

  ## Public Interface

  `start_link/1`

  `forward/1`

  `forward/2`

  `intent/0`

  ## Separation refactor

  By removing the `alternate/2` and `fill_topics` and replacing them with the generic
  `forward/1` or `forward/2`, you get the benefit of consistency, better separation
  and encapsulation.

  #### better separation

  Removing the `alternative/2` you separate the part where a Dialog decides which
  action to take based on the reaction of a Topic.

  #### encapsulation

  You don't really (need to) know how the Topic does its job, other than a standard
  generic contract - it reacts(using `forward/1`, `forward/2`) to the Dialog and to
  intentions, advancing in its state as it uses differrent capabilities and filling
  their needs for input(slots).

  ## topic reaction

  The reaction of a topic(calling `Topic.forward/1` or `Topic.forward/2`) is the
  side-effect that the topic is expressing. It modified its internal state and
  always gives a reaction when invoked.

  The reaction makes the case of a simpler Dialog, where you have multiple
  paths/routes where a Dialog might chose. The chosing strategy is by pattern
  matching and then delegating to every reaction used by the Dialog.

  ## carrier bearer

  This is a special kind of intent which carries entities which will be used
  to complete the capabilities that respond to them and it is used when
  calling `Topic.forward/2`:

    "takes each capability, test it for compability againts the intent,
    filters out `:input` capabilities and `:nomatches` then takes the compatible
    ones and completes them by calling `Capability.complete/2`"
  """

  use GenServer

  alias Dobar.Intent
  alias Dobar.Dialog.Capability
  alias Dobar.Conversation.Intention.Provider, as: IntentionProvider

  @doc """
  Starts a new Topic that represents the given `Dobar.Modal.Intent` while
  prefilling the capabilities with the %Intent

  Starts a new Topic with a strict set of capabilities handed over by the caller.
  The topic's capabilities will be constructued manually, added to the provided intent.
  """
  def start_link(%Intent{} = intent, [definitions: definitions]) do
    GenServer.start_link(__MODULE__, [intent: intent, definitions: definitions])
  end
  def start_link(%Intent{} = intent, [capabilities: capabilities]) do
    GenServer.start_link(__MODULE__, [intent: intent, capabilities: capabilities])
  end

  @doc """
  Reacts with the current state of the Topic

  Will complete the next possible topic and return the next subject capability
  if any left.

  Will complete for each and every entity inside the entities list and return the
  next subject capability if any left.
  """
  def forward(pid), do: GenServer.call pid, {:forward, nil}
  def forward(pid, %Intent{} = intent), do: GenServer.call pid, {:forward, intent}

  @doc """
  Topic's intent stored in the state of the server
  """
  def intent(pid), do: GenServer.call pid, :get_intent

  @doc """
  Gets the representation of all the capabilities of the current topic.
  """
  def capabilities(pid), do: GenServer.call pid, :get_capabilities

  def init([intent: %Intent{} = intent, definitions: definitions]) do
    available_capabilities(intent, definitions)
    |> Enum.filter(&(is_tuple(&1)))
    |> Enum.map(&(create_capability(&1, intent)))
    |> build_state(intent)
  end
  def init([intent: %Intent{} = intent, capabilities: capabilities]) do
    capabilities
    |> Enum.map(&({elem(&1, 0), elem(&1, 1)}))
    |> Enum.map(&(create_capability(&1, intent)))
    |> build_state(intent)
  end

  def handle_call({:forward, nil}, _from, state) do
    answer = case next_capability(state.capabilities) do
      {:ok, capability} ->
        {:question, Capability.outcome(capability.pid)}
      {:completed, topics} ->
        {:completed, topics}
    end
    {:reply, answer, state}
  end
  def handle_call({:forward, %Intent{name: "carrier_bearer"} = intent}, _from, state) do
    # takes each capability, test it for compability againts the intent,
    # filters out `:input` capabilities and `:nomatches` then takes the compatible
    # ones and completes them by calling `Capability.complete/2`
    # note that it can't be used for :message_body because shit!
    state.capabilities
    |> Stream.map(&(%{cpid: &1.pid, compat: Capability.compatibility(&1.pid, intent)}))
    |> Stream.filter(&(elem(&1.compat, 0) != :nomatch))
    |> Stream.each(&(Capability.complete(&1.cpid, intent)))
    |> Stream.run

    answer = case next_capability(state.capabilities) do
      {:ok, capability} ->
        {:question, Capability.outcome(capability.pid)}
      {:completed, topics} ->
        {:completed, topics}
    end

    {:reply, answer, state}
  end
  def handle_call({:forward, %Intent{} = intent}, _from, state) do
    # takes the next capability, tests it for compability match and if compatible,
    # completes it with the intent and asks for the next capability of the topic
    topic_status =
      with {:ok, expected}   <- next_capability(state.capabilities),
           {:ok, capability} <- capability_match(expected, intent),
           :ok               <- Capability.complete(capability.pid, intent),
      do:  next_capability(state.capabilities)

    answer = case topic_status do
      {:ok, capability} ->
        {:question, Capability.outcome(capability.pid)}
      {:completed, topics} ->
        {:completed, topics}
      {:nomatch, _reason} ->
        {:nomatch, state.intent}
    end

    {:reply, answer, state}
  end
  def handle_call(:get_intent, _from, state) do
    {:reply, state.intent, state}
  end
  def handle_call(:get_capabilities, _from, state) do
    capabilities =
      state.capabilities
      |> Enum.map(&(Capability.structure(&1.pid)))
    {:reply, capabilities, state}
  end

  # private

  defp incompleted_topics(capabilities) do
    capabilities
    |> Enum.map(&(%{capability: &1, completed: Capability.completed?(&1.pid)}))
    |> Enum.filter(&(&1[:completed] == false))
    |> Enum.sort(
      &(Capability.priority(&1.capability.pid) < Capability.priority(&2.capability.pid)))
    |> Enum.map(&(&1.capability))
  end

  defp available_capabilities(%Intent{} = intent, definitions) do
    intent_name = intent.name |> String.to_atom

    case definitions.intention(intent_name) do
      {:ok, intent_def} ->
        filter_capabilities(intent_def[intent_name])
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
        capabilities = capabilities
        |> Enum.map(&(Capability.structure(&1.pid)))
        |> List.foldl(%{}, &(Map.put(&2, Map.get(&1, :name), &1)))
        {:completed, capabilities}
      capability ->
        {:ok, capability}
    end
  end

  # this actually tests if the capability is compatible with the entities
  # inside the intent
  defp capability_match(capability, intent) do
    case Capability.compatibility(capability.pid, intent) do
      {:match, _key} -> {:ok, capability}
      {:nomatch, key} -> {:nomatch, "no match for key #{inspect key}"}
    end
  end

  defp filter_capabilities(capabilities) do
    capabilities
    |> Enum.filter(fn {name, desc} -> name != :relationship end)
    |> Enum.filter(fn {name, desc} ->
      is_nil(Keyword.get(desc, :reference)) == true
    end)
    |> Enum.map(fn(x) -> {elem(x, 0), Enum.into(elem(x, 1), %{})} end)
  end

  defp build_state([], intent) do
    {:ok, %{intent: intent, capabilities: []}}
  end
  defp build_state([_h | _t] = capabilities, intent) do
    {:ok, %{intent: intent, capabilities: capabilities}}
  end
end
