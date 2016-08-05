defmodule Dobar.Dialog.Species do
  defmacro __using__(_opts) do
    quote do
      use GenServer

      alias Dobar.Model.Reaction
      alias Dobar.Model.Intent
      alias Dobar.Conversation.Topic
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
      def handle_intent(%Intent{} = intent, %{topic: topic, meta: nil, parent: parent}) do
        IO.puts "continue topic: #{inspect intent}"

        case Topic.react(topic, intent) do
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
            IO.puts "will search for intent: #{inspect intent}"
            IO.puts "reaction type: #{inspect reaction.type}"
            IO.puts "reaction features: #{inspect reaction.features}"

            topic_intent = Topic.intent(topic)

            alternative = intent.name
              |> String.to_atom
              |> find_alternative(String.to_atom(topic_intent.name))
              |> validate_alternative(intent)

            case alternative do
              {:reference, intention} ->
                IO.puts "reference found: #{inspect intention}"

                Process.flag(:trap_exit, true)

                dialog = Dobar.Dialog.SpeciesRoutes.dialog intent.name
                {:ok, pid} = dialog.start_link(self)
                dialog.evaluate(pid, intent)

                {:topic_alternative, {reaction, %{meta: pid}}}

              {:alternative, intention} ->
                IO.puts "alternative dialog: #{inspect intention}"

                Process.flag(:trap_exit, true)

                dialog = Dobar.Dialog.SpeciesRoutes.dialog(intent.name)
                {:ok, pid} = dialog.start_link(self, intention)

                switch_intent = %Intent{name: "switch_conversation",
                                        confidence: 1,
                                        input: "confirm your shit"}
                dialog.evaluate(pid, switch_intent)

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
              # there exists the `:completed` message wich dies and sends a list
              # of capabilities values, that the parent should add to its
              # own capabilities
              GenServer.cast state.parent, {:meta, :canceled}
            end
            {:topic_end, :completed}

          [{:approve, %{entity: :infirm}, "no"}] ->
            IO.puts "no, continue with the dialog"

            case Topic.react(state.topic) do
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
            IO.puts "no, continue the dialog"

            case Topic.react(state.topic) do
              %Reaction{type: :question} = reaction ->
                IO.puts "reaction type: #{inspect reaction.type}"
                IO.puts "reaction features: #{inspect reaction.features}"
                IO.puts "________________________________________________"
                # {:noreply, Map.merge(state, %{meta: nil})}
                {:topic_output, {reaction, %{meta: nil}}}

              # It could be a bug if thise will ever match, because it should be
              # impossible to try to switch to a new conversation while the
              # dialog has already been completed(or the state is broken!)
              %Reaction{type: :completed} = reaction ->
                IO.puts "wahaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaout"
                IO.puts "reaction type: #{inspect reaction.type}"
                IO.puts "reaction features: #{inspect reaction.features}"
                # {:stop, :normal, nil}
                {:topic_end, :completed}
            end
        end
      end
      def handle_meta(%Reaction{intent: %{name: "change_field"}} = reaction, state) do
        IO.puts "handle_meta change_field"

        case reaction.features do
          [{:approve, %{entity: :confirm}, "yes"}] ->
            IO.puts "yes, now change the fields"

            # NOT USED ATM
            # topic_capabilities = Topic.capabilities(state.topic)
            # entities = reaction.intent.entities.field_type

            # capabilities = case compare_capabilities(topic_capabilities, entities) do
            #   {:ok, capabilities} -> capabilities
            #   {:error, reason} -> raise "cannot match capabilities against intent entities"
            # end

            # matches = topic_capabilities
            # |> Enum.filter(&(entities_matches(elem(&1, 1).entity, capabilities)))

            intent = %Intent{name: "purge_change_fields",
                             entities: reaction.intent.entities,
                             confidence: 1}

            dialog = Dobar.Dialog.SpeciesRoutes.dialog intent.name
            {:ok, pid} = dialog.start_link(self)
            dialog.evaluate(pid, intent)

            {:topic_output, {%Reaction{}, %{meta: pid}}}

          [{:approve, %{entity: :infirm}, "no"}] ->
            IO.puts "no, do not change fields; continue with current dialog"

            case Topic.react(state.topic) do
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
      def handle_meta(%Reaction{intent: %{name: "purge_change_fields"}} = reaction, state) do
        IO.puts "handle_meta purge_change_fields"

        case Topic.react(state.topic, carrier_bearer(reaction.features)) do
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
      def handle_meta(:canceled, state) do
        IO.puts "meta died! should continue with the dialog"
        case Topic.react(state.topic) do
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

      def handle_call(:topic_capabilities, _from, %{topic: topic} = state) do
        {:reply, Topic.capabilities(topic), state}
      end

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
      def handle_cast({:evaluate, intent}, %{meta: meta, parent: parent} = state) do
        GenServer.cast meta, {:evaluate, intent}
        {:noreply, state}
      end
      def handle_cast({:meta, %Reaction{} = reaction}, state) do
        case handle_meta(reaction, state) do
          {:topic_output, {output, some_state}} ->
            {:noreply, Map.merge(state, some_state)}
          {:topic_end, :completed} ->
            {:stop, :normal, nil}
        end
      end
      def handle_cast({:meta, :canceled}, state) do
        case handle_meta(:canceled, state) do
          {:topic_output, {output, some_state}} ->
            {:noreply, Map.merge(state, some_state)}
          {:topic_end, :completed} ->
            {:stop, :normal, nil}
        end
      end

      def handle_info({:EXIT, _from, reason}, state) do
        IO.puts "EXIIIIIIIIIIIIIIIIT: #{inspect reason}"
        {:noreply, state}
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

      defp compare_capabilities(capabilities, entities) do
        capabilities = capabilities
        |> Enum.map(&(elem(&1, 1).entity))
        |> List.flatten
        |> MapSet.new

        entities = entities
        |> Enum.map(&(String.to_atom &1.value))
        |> MapSet.new

        intersection = MapSet.intersection entities, capabilities

        # send the compared entities for the case when you start to notify
        # the user that he didn't pick all the right fields to "change"
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

      defp carrier_bearer(features) do
        entities = features
        |> List.foldl(%{}, fn feature, acc ->
          field_name = elem(feature, 1).entity
          entity = [%{confidence: 1, type: "value", value: elem(feature, 2)}]
          field_map = Map.put(%{}, field_name, entity)
          Map.merge(acc, field_map)
        end)

        %Intent{name: "carrier_bearer", entities: entities}
      end
    end
  end
end
