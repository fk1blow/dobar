defmodule Dobar.Dialog.PurgeChangeFieldsDialog do
  use Dobar.Dialog.Species

  def handle_intent(%Intent{} = intent, %{topic: nil, meta: nil, parent: parent}) do
    IO.puts "purge change fields; begin topic: #{inspect intent}"

    Process.flag(:trap_exit, true)

    parent_capabilities = GenServer.call(parent, :topic_capabilities)

    entities = intent.entities.field_type
    capabilities = case compare_capabilities(parent_capabilities, entities) do
      {:ok, capabilities} -> capabilities
      {:error, reason} -> raise "cannot match capabilities against intent entities"
    end

    matches = parent_capabilities
    |> Enum.filter(&(entities_matches(elem(&1, 1).entity, capabilities)))

    intent = %Intent{name: "purge_change_fields", confidence: 1}
    {:ok, topic} = Topic.start_link(intent, matches)

    case Topic.react(topic) do
      %Reaction{type: :question} = reaction ->
        IO.puts "reaction type: #{inspect reaction.type}"
        IO.puts "reaction features: #{inspect reaction.features}"
        IO.puts "________________________________________________"
        {:topic_output, {reaction, %{topic: topic}}}

      %Reaction{type: :completed} = reaction ->
        IO.puts "reaction type: #{inspect reaction.type}"
        IO.puts "reaction features: #{inspect reaction.features}"
        unless root_dialog?(self) do
          GenServer.cast parent, {:meta, reaction}
        end
        {:topic_end, :completed}
    end
  end

  def handle_intent(intent, state) do
    super(intent, state)
  end
end
