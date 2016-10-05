defmodule Dobar.Dialog.PurgeChangeFieldsDialog do
  use Dobar.Dialog.Species

  alias Dobar.Dialog.Capability.Feature

  # this basically tries to match the incoming fields the user wants to change,
  # agains the fields of the parent dialog(the actual target).
  def handle_intent(%Intent{} = intent, %{topic: nil, meta: nil} = state) do
    parent_capabilities = GenServer.call(state.parent, :topic_capabilities)
    intent_entities = intent.entities.field_type
    capabilities = prefilled_capabilities(intent_entities, parent_capabilities)

    if Enum.count(capabilities) == 0 do
      GenEvent.notify(state.event_manager,
        %Reaction{about: :purge_nomatches, trigger: intent})
      if (meta_dialog?(self)),
        do: GenServer.cast(state.parent, {:meta, :canceled})
      {:error, :purge_nomatches}
    else
      intent = %Intent{name: "purge_change_fields", confidence: 1}
      {:ok, topic} = Topic.start_link(intent, [capabilities: capabilities])

      case Topic.forward(topic) do
        {:question, question} ->
          GenEvent.notify(state.event_manager, %Reaction{about: :question, text: question})
          {:topic_output, %{topic: topic}}

        {:completed, intent, _features} ->
          GenEvent.notify(state.event_manager, %Reaction{about: :completed, text: "ok"})
          unless root_dialog?(self) do
            GenServer.cast(state.parent,
              {:meta, %Dobar.Dialog.Meta{intent: intent, passthrough: state.passthrough}})
          end
          {:topic_end, :completed}
      end
    end
  end

  def handle_intent(intent, state) do
    super(intent, state)
  end

  defp prefilled_capabilities(entities, capabilities) do
    capabilities_set =
      capabilities
      |> Enum.map(&(Map.get(&1, :slots)))
      |> List.flatten
      |> MapSet.new

    entities_set =
      entities
      |> Enum.map(&(Map.get(&1, :value) |> String.to_atom))
      |> MapSet.new

    matching_capabilities = MapSet.intersection(capabilities_set, entities_set)

    # take the matching capabilities
    # filter the items which don't intersect with matching_capabilities
    # take each remaining feature
    # take the keys of the feature, filter them, and build a map with them
    # take the map of the keys/feature and build a keyword that contains it
    case MapSet.size(matching_capabilities) do
      0 -> []
      _n ->
        capabilities
        |> Enum.filter(fn capability ->
          case capability.slots do
            [_ | _] = slots ->
              MapSet.new(slots)
              |> MapSet.intersection(matching_capabilities)
              |> MapSet.size > 0
            element when is_atom(element) ->
              MapSet.member?(matching_capabilities, element)
          end
        end)
        |> Enum.map(fn(%Feature{} = feature) ->
          restricts = [:name, :matched, :value, :__struct__]
          entity =
            feature
            |> Map.keys
            |> Enum.reject(&(Enum.member? restricts, &1))
            |> List.foldl(%{}, fn x, acc ->
              if (x == :slots),
                do: Map.put(acc, :entity, Map.get(feature, x)),
                else: Map.put(acc, x, Map.get(feature, x))
            end)
          {feature.name, entity}
        end)
    end
  end
end
