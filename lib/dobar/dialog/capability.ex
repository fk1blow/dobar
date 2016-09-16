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

  alias Dobar.Model.Intent

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
    capability = args[:capability]
    {:ok, %{name: elem(capability, 0),
            capability: elem(capability, 1),
            value: prefill_value(args[:prefill], elem(capability, 1)),
            pseudo: elem(capability, 1)}}
  end

  def handle_call(:is_completed, _from, state) do
    is_completed = is_nil(state.value) == false
    {:reply, is_completed, state}
  end

  def handle_call(:get_priority, _from, state) do
    {:reply, state.capability.prio, state}
  end

  def handle_call(:get_outcome, _from, state) do
    # TODO: in the (not so) near future, change this hardcoded question
    question = "please provide a value for: #{inspect state.capability.entity}"
    {:reply, question, state}
  end

  def handle_call({:compatibility, %Intent{} = intent}, _from, state) do
    capability_entities = state.capability.entity

    x = match_entity(capability_entities, intent)

    IO.puts "xxxxxxxxxxxxx: #{inspect state.capability}"
    IO.puts "xxxxxxxxxxxxx: #{inspect x}"

    match = case match_entity(capability_entities, intent) do
      nil   -> {:nomatch, capability_entities, intent}
      [h|t] -> {:match, capability_entities, h}
    end
    {:reply, match, state}
  end

  def handle_call({:complete, %Intent{entities: entities} = intent}, _from, state) do
    capability_entities = state.capability.entity

    capability_value = case match_entity(capability_entities, intent) do
      nil   -> nil
      [h|t] -> h.value
    end

    new_capability = Map.merge(state.capability,
      %{entity: capability_slot_key(state.capability, intent)})

    new_state = Map.merge(state,
      %{value: capability_value, pseudo: new_capability.entity})

    {:reply, {:ok, capability_value}, new_state}
  end

  def handle_call(:structure, _from, state) do
    answer = %{name: state.name,
               entity: state.pseudo,
               capability: state.capability,
               value: state.value}
    {:reply, answer, state}
  end

  # private
  #

  defp prefill_value(%Intent{} = prefill, %{entity: {:input, entities}}) when is_list entities do
    prefill_value(prefill, %{entity: entities})
  end
  defp prefill_value(%Intent{} = prefill, %{entity: entities}) when is_list entities do
    IO.puts "prefill_____: #{inspect prefill}"
    IO.puts "prefill_____: #{inspect entities}"
    case match_entity(entities, prefill) do
      nil    -> nil
      entity -> List.first(entity).value
    end
  end
  defp prefill_value(%Intent{} = prefill, %{entity: entity}) when is_atom entity do
    case prefill.entities[entity] do
      nil    -> nil
      entity -> List.first(entity).value
    end
  end
  defp prefill_value(%Intent{} = prefill, %{entity: entity}) when is_bitstring entity do
    entity = entity |> String.to_atom
    case prefill.entities[entity] do
      nil    -> nil
      entity -> List.first(entity).value
    end
  end

  defp match_entity({:input, entities}, %Intent{} = intent_target) do
    [%{confidence: 1, type: "value", value: intent_target |> Map.get(:input)}]
    # IO.puts "match_entity entities: #{inspect entities}"
    # IO.puts "match_entity intent: #{inspect intent_target}"
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
end
