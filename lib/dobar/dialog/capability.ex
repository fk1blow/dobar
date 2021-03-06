defmodule Dobar.Dialog.Capability do
  @moduledoc """
  The capability represents a single unit that describes a feature of the topic.

  The Capability of a topic is a simple declaration of a reaction - dobar can
  react to "what is the current time?" or "send a message" or "the receive is Cipo".

  It is the caracteristics of a specific Topic inside a conversation. Each Dialog
  has a Topic of discussion; the whole Topic is centered around Dobar reacting to
  input so to do it, it uses capabilities.

  ### pros

    _reactive, proactive, inert, alert capabilities_

  The "reactive" and "proactive" capabilities are two of the many types of
  behaviours Dobar can have.

  Separation
  ----------

  The capabilities are separated by two criteria:
    - by how they react to the input
    - and by how they evaluate that input

  #### by how it reacts to input

  Referring to how a Capability processes its input, there are two types:
    1. reactive
    2. proactive

  and by how they evaluate the input
    1. inert
    2. alert

  ## Reactive

  A capability is said to be "reactive" if, when presented with an input(tipically
  wrapped as an Intent), it reacts only when it detects the values that it cares

  The "reactive" capability simply evaluated the given input and reacts only if
  it matches its type of slot/feature, eg: "send message to Cipo", where "Cipo"
  is the contact capability that a topic might contain.

  ## Proactive

  A "proactive" capability has the initiative of the Dialog when presented with
  a specific input(wrapped as an Intent), eg: "do you want to add a label to the alarm?".

  Usually, a "proactive" capability takes the initiative and it asks questions
  back to the user/human/program.

  ## Inert

  It is said to be "inert" a capability that computes the outcome of the input
  presented to the capability; it is a linear separability problem,
  "this or that" and doesn't need some external service in order to compute an outcome.

  ## Alert

  Alert is a capability that will want to communication with the outside
  (or its features data bank) in order to provide an outcome. eg: tries to match
  a contact for the current acount but needs to search it inside some `contacts`
  external service/api.
  """

  use GenServer

  alias Dobar.Intent
  alias Dobar.Dialog.Capability.Feature

  @confidence_treshold 0.8

  def start_link(capability, intent) do
    GenServer.start_link __MODULE__, [capability: capability, prefill: intent]
  end

  def complete(pid, %Intent{} = intent) do
    GenServer.call(pid, {:complete, intent})
  end

  def completed?(pid) do
    GenServer.call(pid, :is_completed)
  end

  def compatibility(pid, %Intent{} = intent) do
    GenServer.call(pid, {:compatibility, intent})
  end

  def outcome(pid) do
    GenServer.call(pid, :get_outcome)
  end

  def priority(pid) do
    GenServer.call(pid, :get_priority)
  end

  def structure(pid) do
    GenServer.call(pid, :structure)
  end

  # callbacks
  #

  def init(args) do
    {name, desc} = args[:capability]

    prefill = if is_nil(Map.get(desc, :prefill)), do: true, else: Map.get(desc, :prefill)
    slots = desc.entity || []
    value = prefill_slots_values(desc, name, args[:prefill])
    matched = prefill_matched_values(desc, args[:prefill])
    prio = Map.get(desc, :prio) || 0

    feature = %Feature{
      name: name,
      slots: slots,
      value: value,
      matched: matched,
      prio: prio,
      prefill: prefill,
      inert: desc[:inert] || false
    }

    {:ok, feature}
  end

  def handle_call(:is_completed, _from, %{inert: true, value: nil} = state) do
    {:reply, true, state}
  end
  def handle_call(:is_completed, _from, %{inert: true, value: value} = state) do
    {:reply, true, state}
  end
  def handle_call(:is_completed, _from, %{value: value} = state) do
    {:reply, is_nil(value) == false, state}
  end
  def handle_call(:get_priority, _from, state) do
    {:reply, state.prio, state}
  end
  def handle_call(:get_outcome, _from, state) do
    # TODO: in the (not so) near future, change this hardcoded question
    question = "please provide a value for: #{inspect state.slots}"
    {:reply, question, state}
  end
  def handle_call({:compatibility, %Intent{name: "carrier_bearer"} = intent}, _from, state) do
    match =
      if Enum.find_value(state.slots, &(&1 == :raw_input)) do
        matched_slots =
          state.slots
          |> MapSet.new
          |> MapSet.intersection(Map.keys(intent.entities) |> MapSet.new)
          |> MapSet.to_list

        slots_values =
          matched_slots
          |> Enum.map(fn item ->
            Map.get(intent.entities, item) |> Enum.map(&(Map.get(&1, :value)))
          end)
          |> List.flatten

        case slots_values do
          [_h | _t] ->
            {:match, :raw_input}
          _ ->
            {:nomatch, state.slots}
        end
      else
        matches =
          state.slots
          |> MapSet.new
          |> MapSet.intersection(intent |> exclude_inconfident |> MapSet.new)
          |> MapSet.to_list

        case matches do
          [] -> {:nomatch, state.slots}
          [h | t] -> {:match, matches}
        end
      end

    {:reply, match, state}
  end
  def handle_call({:compatibility, %Intent{} = intent}, _from, state) do
    match =
      if Enum.find_value(state.slots, &(&1 == :raw_input)) do
        {:match, :raw_input}
      else
        matches =
          state.slots
          |> MapSet.new
          |> MapSet.intersection(intent |> exclude_inconfident |> MapSet.new)
          |> MapSet.to_list

        case matches do
          [] -> {:nomatch, state.slots}
          [h | t] -> {:match, matches}
        end
      end

    {:reply, match, state}
  end
  def handle_call({:complete, %Intent{entities: entities} = intent}, _from, state) do
    matched_slots =
      state.slots
      |> MapSet.new
      |> MapSet.intersection(Map.keys(intent.entities) |> MapSet.new)
      |> MapSet.to_list

    slots_values =
      matched_slots
      |> Enum.map(fn item ->
        Map.get(intent.entities, item) |> Enum.map(&(Map.get(&1, :value)))
      end)
      |> List.flatten

    if Enum.find_value(state.slots, &(&1 == :raw_input)) do
      # check if the slots are empty and if the intent's input is nil then nil,
      # otherwise return the intent's input
      value = if Enum.empty?(slots_values) do
        if is_nil(intent.input), do: nil, else: [intent.input]
      else
        slots_values
      end
      {:reply, :ok, Map.put(state, :value, value)}
    else
      state = case slots_values do
        [h | t] ->
          Map.put(state, :value, slots_values) |> Map.put(:matched, hd(matched_slots))
        [] ->
          state
      end
      {:reply, :ok, state}
    end
  end
  def handle_call(:structure, _from, state) do
    {:reply, state, state}
  end

  # private

  defp prefill_slots_values(%{entity: [h | t]} = desc, name, intent) do
    slots_values =
      MapSet.new(desc.entity)
      |> MapSet.intersection(Map.keys(intent.entities) |> MapSet.new)
      |> MapSet.to_list
      |> Enum.map(fn item ->
        Map.get(intent.entities, item) |> Enum.map(&(Map.get(&1, :value)))
      end)
      |> List.flatten
    case slots_values do
      [h | t] -> slots_values
      [] -> nil
    end
  end

  defp prefill_matched_values(desc, intent) do
    MapSet.new(desc.entity)
    |> MapSet.intersection(Map.keys(intent.entities) |> MapSet.new)
    |> MapSet.to_list
    |> List.first
  end

  defp match_entity(:input, %Intent{} = intent_target) do
    [%{confidence: 1, type: "value", value: intent_target |> Map.get(:input)}]
  end
  defp match_entity(entities, %Intent{} = intent_target) when is_bitstring entities do
    intent_target.entities[String.to_atom entities]
  end
  defp match_entity(entities, %Intent{} = target) when is_list entities do
    case Enum.find(entities, &(target.entities[&1])) do
      nil -> nil
      entity -> target.entities[entity]
    end
  end

  defp capability_slot_key(capability, %Intent{entities: entities}) do
    case capability.entity do
      [h|t] -> capability.entity |> Enum.find(&(entities[&1]))
      _     -> capability.entity
    end
  end

  defp exclude_inconfident(%Intent{} = intent) do
    intent.entities
    |> Map.keys
    |> Enum.filter(fn x ->
      intent.entities[x]
      |> Enum.filter(fn k -> k.confidence > @confidence_treshold end)
      |> Enum.count > 0
    end)
  end
end
