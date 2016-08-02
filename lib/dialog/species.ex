defmodule Dobar.Dialog.Species do
  defmacro __using__(_opts) do
    quote do
      use GenServer

      alias Dobar.Model.Reaction
      alias Dobar.Model.Intent
      alias Dobar.Conversation.Intention.Provider, as: IntentionProvider

      @confidence_treshold 0.8

      # public interface
      #

      def start_link(:root_dialog) do
        GenServer.start_link __MODULE__, [parent: nil], name: :root_dialog
      end
      def start_link(parent) do
        GenServer.start_link __MODULE__, [parent: parent]
      end
      def start_link(parent, passthrough) do
        GenServer.start_link __MODULE__, [parent: parent, passthrough: passthrough]
      end

      def evaluate(pid, %Intent{} = intent) do
        GenServer.cast pid, {:evaluate, intent}
      end

      # overridable delegates
      #

      def handle_intent(%Intent{} = intent, %{topic: nil, meta: nil, parent: parent}) do
        IO.puts "#{inspect self} begin topic: #{inspect intent}"

        Process.flag(:trap_exit, true)

        {:ok, topic} = Dobar.Conversation.Topic.start_link(intent)

        case Dobar.Conversation.Topic.react(topic) do
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

      def handle_intent(%Intent{} = intent, %{topic: topic, meta: nil, parent: parent}) do
        IO.puts "continue topic: #{inspect intent}"

        case Dobar.Conversation.Topic.react(topic, intent) do
          %Reaction{type: :question} = reaction ->
            IO.puts "reaction type: #{inspect reaction.type}"
            IO.puts "reaction features: #{inspect reaction.features}"
            IO.puts "________________________________________________"

            {:topic_output, {reaction, nil}}

          %Reaction{type: :completed} = reaction ->
            IO.puts "reaction type: #{inspect reaction.type}"
            IO.puts "reaction features: #{inspect reaction.features}"

            unless root_dialog?(self) do
              IO.puts "ending topic, intent: #{inspect intent}"
              GenServer.cast parent, {:meta, reaction}
            end

            {:topic_end, :completed}

          %Reaction{type: :nomatch} = reaction ->
            IO.puts "cannot match"
            IO.puts "reaction type: #{inspect reaction.type}"
            IO.puts "reaction features: #{inspect reaction.features}"

            topic_intent = Dobar.Conversation.Topic.intent(topic)

            alternative = intent.name
              |> String.to_atom
              |> find_alternative(String.to_atom(topic_intent.name))
              |> validate_alternative(intent)

            case alternative do
              {:reference, intention} ->
                IO.puts "reference found: #{inspect intention}"

                Process.flag(:trap_exit, true)

                reference_dialog = Dobar.Dialog.SpeciesRoutes.dialog intent.name
                {:ok, pid} = reference_dialog.start_link self
                reference_dialog.evaluate pid, intent

                {:topic_alternative, {reaction, %{meta: pid}}}

              {:alternative, intention} ->
                IO.puts "alternative dialog: #{inspect intention}"

                Process.flag(:trap_exit, true)

                reference_dialog = Dobar.Dialog.SpeciesRoutes.dialog intent.name
                {:ok, pid} = reference_dialog.start_link self, intention

                switch_intent = %Intent{name: "switch_conversation",
                                        confidence: 1,
                                        input: "confirm your shit"}
                reference_dialog.evaluate pid, switch_intent

                {:topic_alternative, {reaction, %{meta: pid}}}

              {:noalternative, intention} ->
                IO.puts "no alternative found: #{inspect intention}"
                {:topic_nomatch, intention}
            end
        end
      end

      def handle_meta(%Reaction{intent: %{name: "cancel_command"}} = reaction, state) do
        IO.puts "meta ended by: cancel"
        IO.puts "reaction from meta: #{inspect reaction}"

        case reaction.features do
          [{:approve, %{entity: :confirm}, "yes"}] ->
            IO.puts "ok, kill this dialog"

            unless root_dialog?(self) do
              GenServer.cast state.parent, {:meta, :continue}
            end
            {:topic_end, :completed}

          [{:approve, %{entity: :infirm}, "no"}] ->
            IO.puts "no, continue with the dialog"

            case Dobar.Conversation.Topic.react(state.topic) do
              %Reaction{type: :question} = reaction ->
                IO.puts "reaction type: #{inspect reaction.type}"
                IO.puts "reaction features: #{inspect reaction.features}"
                IO.puts "________________________________________________"
                {:topic_output, {reaction, %{meta: nil}}}

              %Reaction{type: :completed} = reaction ->
                IO.puts "wahaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaout"
                IO.puts "reaction type: #{inspect reaction.type}"
                IO.puts "reaction features: #{inspect reaction.features}"
                {:topic_end, :completed}
            end
        end
      end
      def handle_meta(%Reaction{intent: %{name: "switch_conversation"}} = reaction, state) do
        IO.puts "meta ended by: switch"
        IO.puts "reaction from meta: #{inspect reaction}"

        case reaction.features do
          [{:approve, %{entity: :confirm}, "yes"}] ->
            IO.puts "ok, kill this (alternative)dialog"
            # If it's the root dialog, just send this away(to an event handler,
            # at some point), else send the meta to the parent(chain)
            if root_dialog?(self) do
              IO.puts "ROOT: should do something with this alternative-reaction dialog"
            else
              GenServer.cast state.parent, {:meta, reaction}
            end
            # {:stop, :normal, nil}
            {:topic_end, :completed}

          [{:approve, %{entity: :infirm}, "no"}] ->
            IO.puts "no, continue with the dialog"

            case Dobar.Conversation.Topic.react(state.topic) do
              %Reaction{type: :question} = reaction ->
                IO.puts "reaction type: #{inspect reaction.type}"
                IO.puts "reaction features: #{inspect reaction.features}"
                IO.puts "________________________________________________"
                # {:noreply, Map.merge(state, %{meta: nil})}
                {:topic_output, {reaction, %{meta: nil}}}
              %Reaction{type: :completed} = reaction ->
                IO.puts "wahaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaout"
                IO.puts "reaction type: #{inspect reaction.type}"
                IO.puts "reaction features: #{inspect reaction.features}"
                # {:stop, :normal, nil}
                {:topic_end, :completed}
            end
        end
      end
      def handle_meta(:continue, state) do
        IO.puts "meta died! should continue with the dialog"
        case Dobar.Conversation.Topic.react(state.topic) do
          %Reaction{type: :question} = reaction ->
            IO.puts "reaction type: #{inspect reaction.type}"
            IO.puts "reaction features: #{inspect reaction.features}"
            IO.puts "________________________________________________"
            {:topic_output, {reaction, %{meta: nil}}}

          %Reaction{type: :completed} = reaction ->
            IO.puts "reaction type: #{inspect reaction.type}"
            IO.puts "reaction features: #{inspect reaction.features}"
            {:topic_end, :completed}
        end
      end

      defoverridable [handle_intent: 2, handle_meta: 2]

      # callbacks
      #

      def init([parent: nil]) do
        {:ok, %{topic: nil, meta: nil, parent: nil}}
      end
      def init([parent: parent]) do
        {:ok, %{topic: nil, meta: nil, parent: parent}}
      end
      def init([parent: parent, passthrough: passthrough]) do
        {:ok, %{topic: nil, meta: nil, parent: parent, passthrough: passthrough}}
      end

      @doc """
      Handles the intent evaluation when a topic already exist but not a meta.
      """
      def handle_cast({:evaluate, intent}, %{topic: topic, meta: nil} = state) do
        case handle_intent intent, state do
          {:topic_output, {output, nil}} ->
            {:noreply, state}

          {:topic_output, {output, some_state}} ->
            {:noreply, Map.merge(state, some_state)}

          {:topic_end, :completed} ->
            {:stop, :normal, nil}

          {:topic_alternative, {ouput, some_state}} ->
            {:noreply, Map.merge(state, some_state)}

          {:topic_nomatch, for_intention} ->
            {:noreply, state}
        end
      end

      @doc """
      Handles the intent evaluation when a meta exists, passing/delegating the conversation
      to the meta dialog process.
      """
      def handle_cast({:evaluate, intent}, %{meta: meta, parent: parent} = state) do
        GenServer.cast meta, {:evaluate, intent}
        {:noreply, state}
      end

      def handle_cast({:meta, %Reaction{} = reaction}, state) do
        case handle_meta reaction, state do
          {:topic_output, {output, some_state}} ->
            {:noreply, Map.merge(state, some_state)}
          {:topic_end, :completed} ->
            {:stop, :normal, nil}
        end
      end

      def handle_cast({:meta, :continue}, state) do
        case handle_meta :continue, state do
          {:topic_output, {output, some_state}} ->
            {:noreply, Map.merge(state, some_state)}
          {:topic_end, :completed} ->
            {:stop, :normal, nil}
        end
      end

      # private
      #

      defp root_dialog?(pid), do: pid == Process.whereis :root_dialog

      # TODO: find if theres a need for this alternative match
      defp find_alternative(intent_name, nil) do
        {:noalternative, nil}
      end
      defp find_alternative(intent_name, topic_intent_name) do
        capability_name = intent_name
        topic_intent_name = topic_intent_name

        # extract the intention for the current topic
        {:ok, intention} = IntentionProvider.intention(topic_intent_name)

        # extract the capabilities of the current topic
        topic_capabilities = intention[topic_intent_name][capability_name]

        # tl;dr it searches first inside the current topic's capabilities and if
        # nothing found, search for an alternative in the global registery.
        #
        # if there's a list expressed in the `topic_capabilities`, it means the topic's
        # current intention has a reference to the input intent - the case will
        # return a {:refernce, intention}. If no list present, it searches for
        # an intention named after `capability_name` and will return an
        # {:alternative, intention}. If that doesn't find an intention, it finally
        # returns a {:noalternative, intention}
        case topic_capabilities do
          [_head|_tail] ->
            {:reference, intention}
          nil ->
            {:ok, intention} = IntentionProvider.intention(capability_name)
            topic_capabilities = intention[capability_name]

            # if the capability is contextual and applies only for meta, stop
            # searching the global registry - no intention capability found!
            if topic_capabilities[:relationship] == :meta do
              {:noalternative, intention}
            else
              {:alternative, intention}
            end
        end
      end

      defp validate_alternative({:reference, intention}, %Intent{} = input_intent) do
        case input_intent do
          %{confidence: conf} when conf > @confidence_treshold ->
            {:reference, intention}
          _ ->
            {:noalternative, intention}
        end
      end
      defp validate_alternative({:alternative, intention}, %Intent{} = input_intent) do
        case input_intent do
          %{confidence: conf} when conf > @confidence_treshold ->
            {:alternative, intention}
          _ ->
            {:noalternative, intention}
        end
      end
      defp validate_alternative({:noalternative, intention}, _) do
        {:noalternative, intention}
      end
    end
  end
end
