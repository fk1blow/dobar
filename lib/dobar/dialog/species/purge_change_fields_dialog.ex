defmodule Dobar.Dialog.PurgeChangeFieldsDialog do
  use Dobar.Dialog.Species

  def handle_intent(%Intent{} = intent, %{topic: nil, meta: nil} = state) do
    Process.flag(:trap_exit, true)

    parent_capabilities = GenServer.call(state.parent, :topic_capabilities)
    entities = intent.entities.field_type

    capabilities = case intersect_capabilities(parent_capabilities, entities) do
      {:ok, capabilities} -> capabilities
      {:error, reason} -> raise "cannot match capabilities against intent entities"
    end

    # get only the capabilities that are common the both the input intent
    # and the parent's capabilities
    matches =
      parent_capabilities
      |> Map.keys
      |> Enum.map(fn key ->
        {key, Map.get(parent_capabilities, key).capability}
      end)
      |> Enum.filter(fn item ->
        case elem(item, 1) do
          %{} = element -> entities_matches(element.entity, capabilities)
          element -> entities_matches(element, capabilities)
        end
      end)

    intent = %Intent{name: "purge_change_fields", confidence: 1}
    {:ok, topic} = Topic.start_link(intent, matches)

    case Topic.react(topic) do
      {:question, question} ->
        GenEvent.notify(Dobar.DialogEvents, %Reaction{about: :question, text: question})
        {:topic_output, %{topic: topic}}

      {:completed, intent, features} ->
        GenEvent.notify(Dobar.DialogEvents, %Reaction{about: :completed, text: "ok"})
        unless root_dialog?(self) do
          GenServer.cast(state.parent,
            {:meta, %Dobar.Model.Meta{intent: intent, passthrough: state.passthrough}})
        end
        {:topic_end, :completed}
    end
  end

  def handle_intent(intent, state),
    do: super(intent, state)

  # Used when trying to compare between the capabilities of a dialog specie
  # and the received intent entities.
  # It first intersects the entities with the capabilities and after that
  # it tries to check if the intersection is a subset of the entities
  # Note that this function will/should be mostly used for change/purge fields.
  defp intersect_capabilities(%{} = capabilities, entities) do
    capabilities =
      for {key, value} <- capabilities do
        case value.entity do
          %{} = item -> item.entity
          _          -> value.entity
        end
      end
      |> List.flatten
      |> MapSet.new

    entities =
      entities
      |> Enum.map(&(String.to_atom &1.value))
      |> MapSet.new

    intersection = MapSet.intersection entities, capabilities

    case MapSet.subset?(intersection, entities) do
      true -> {:ok, entities}
      false -> {:error, "entities provided not a subset of the capabilities"}
    end
  end

  defp entities_matches([h|t] = entity, capabilities) do
    MapSet.new(entity) |> MapSet.intersection(capabilities) |> MapSet.size > 0
  end
  defp entities_matches(entity, capabilities) do
    Enum.any?(capabilities, fn x -> x == entity end)
  end
end
