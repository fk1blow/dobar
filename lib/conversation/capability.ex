defmodule Dobar.Conversation.Capability do
  @moduledoc """
  The capability represents a single unit that describes a feature of the topic.

  The Capability of a topic is a simple declaration of a reaction - dobar can
  react to "what is the current time?" or "send a message" or "the receive is Cipo".

  It is the caracteristics of a specific Topic inside a conversation. Each Dialog
  has a Topic of discussion; the whole Topic is centered around Dobar reacting to
  input so to 3do it, it uses capabilities.

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
  alias Dobar.Model.Outcome

  def start_link(capability, entities) do
    GenServer.start_link __MODULE__, [capability: capability, prefill: entities]
  end

  def completed?(pid) do
    GenServer.call(pid, :is_completed)
  end

  def priority(pid) do
    GenServer.call(pid, :get_priority)
  end

  def outcome(pid) do
    GenServer.call(pid, :get_outcome)
  end

  def complete?(pid, %Intent{} = intent) do
    GenServer.call(pid, {:can_complete, intent})
  end

  def complete(pid, %Intent{} = intent) do
    GenServer.call(pid, {:complete, intent})
  end

  def structure(pid) do
    GenServer.call(pid, :structure)
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

  def handle_call(:get_outcome, _from, state) do
    # TODO: in the (not so) near future, change this hardcoded question
    question = "please provide a value for: #{inspect state.capability.entity}"
    {:reply, %Outcome{question: question}, state}
  end

  def handle_call({:can_complete, %Intent{entities: entities} = intent}, _from, state) do
    capability_entities = state.capability.entity

    match = case one_of_entity_match(entities, capability_entities) do
      nil -> {:nomatch, capability_entities, intent}
      [h|t] -> {:match, capability_entities, h}
    end




    # match = if is_list(state.capability.entity) do
    #   case Enum.find(state.capability.entity, &(entities[&1])) do
    #     nil -> nil
    #     key ->
    #       case entities[key] do
    #         nil -> {:nomatch, key, intent}
    #         [h|t] -> {:match, key, h}
    #       end
    #   end
    # else
    #   key = String.to_atom state.capability.entity
    #   match = entities[key]
    #   case match do
    #     nil -> {:nomatch, key, intent}
    #     [h|t] -> {:match, key, h}
    #   end
    # end






    # key = String.to_atom state.capability.entity
    # match = intent.entities[key]
    # reply = case match do
    #   nil -> {:nomatch, key, intent}
    #   [h|t] -> {:match, key, h}
    # end
    {:reply, match, state}
  end

  def handle_call({:complete, %Intent{} = intent}, _from, state) do
    key = String.to_atom state.capability.entity
    reply = case intent.entities[key] do
      nil -> nil
      [h|t] -> h.value
    end
    {:reply, {:ok, reply}, Map.merge(state, %{value: reply})}
  end

  def handle_call(:structure, _from, state) do
    # TODO: refactor to return a more appropriate structure of the topic
    {:reply, {:ok, %{name: state.capability.entity, value: state.value}}, state}
  end

  # private
  #

  defp prefill_value(prefill, %{entity: entities}) when is_list entities do
    # get the first entity in the list that can match a key in the prefill map
    # case Enum.find(entities, &(prefill[&1])) do
    #   nil -> nil
    #   entity ->
    #     case prefill[entity] do
    #       nil -> nil
    #       entity -> List.first(entity).value
    #     end
    # end
    case one_of_entity_match(prefill, entities) do
      nil -> nil
      entity -> List.first(entity).value
    end
  end
  defp prefill_value(prefill, %{entity: entity}) do
    IO.puts "prefill: #{inspect prefill}"
    IO.puts "capability: #{inspect entity}"

    entity = String.to_atom entity
    case prefill[entity] do
      nil -> nil
      entity -> List.first(entity).value
    end
  end

  defp one_of_entity_match(target, entity) when is_bitstring entity do
    target[String.to_atom entity]
  end
  defp one_of_entity_match(target, entities) when is_list entities do
    case Enum.find(entities, &(target[&1])) do
      nil -> nil
      entity -> target[entity]
    end
  end
end
