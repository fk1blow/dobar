defmodule Dobar.Dialog.PurgeChangeFieldsDialog do
  use Dobar.Dialog.Species

  def handle_intent(%Intent{} = intent, %{topic: nil, meta: nil} = state) do
    IO.puts "purge change fields; begin topic: #{inspect intent}"

    Process.flag(:trap_exit, true)

    parent_capabilities = GenServer.call(state.parent, :topic_capabilities)
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
      # %Reaction{type: :question} = reaction ->
      {:question, question} ->
        GenEvent.notify(Dobar.DialogEvents, %Reaction{about: :question, text: question})
        {:topic_output, %{topic: topic}}

      # %Reaction{type: :completed} = reaction ->
      {:completed, features} ->
        GenEvent.notify(Dobar.DialogEvents, %Reaction{about: :completed, text: "ok"})
        unless root_dialog?(self) do
          GenServer.cast(state.parent,
            # {:meta, %Meta{reaction: reaction, passthrough: state.passthrough}})
            {:meta, %Dobar.Model.Meta{intent: intent, passthrough: state.passthrough}})
        end
        {:topic_end, :completed}
    end
  end

  def handle_intent(intent, state),
    do: super(intent, state)
end
