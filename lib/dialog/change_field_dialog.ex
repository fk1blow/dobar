defmodule Dobar.Dialog.ChangeFieldDialog do
  @moduledoc """
  This specialized dialog will handle "change_field" intents in a special way.
  Because change field relies mostly on the parent dialog, this specialized dialog
  will have to validate that...

  Note that it can have a "change_field" meta-dialog itself(alongside
  a "cancel_command" meta-dialog).
  """
  use Dobar.Dialog.Species


  def handle_intent(intent, %{topic: nil, meta: nil, parent: parent} = state) do
    IO.puts "#{inspect self} begin topic for: change field dialog: #{inspect intent}"

    {:ok, topic} = Topic.start_link(intent)

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
