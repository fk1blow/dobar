defmodule Dobar.Dialog.Species do
  defmacro __using__(_opts) do
    quote do
      use GenServer

      alias Dobar.Reaction
      alias Dobar.Intent
      alias Dobar.Dialog.Topic
      alias Dobar.Conversation.Intention.Provider, as: IntentionProvider
      alias Dobar.Dialog.Species.Routes, as: SpeciesRoutes

      alias Dobar.DialogEvents

      @confidence_treshold 0.8

      # Public interface

      def start_link(:root_dialog, opts) do
        GenServer.start_link(__MODULE__,
          [parent: nil,
           name: :root_dialog,
           topic: nil,
           meta: nil,
           passthrough: nil,
           event_manager: opts[:event_manager],
           definitions: opts[:definitions]])
      end
      # TODO: add `name` as process register only if opts[:name] exists
      def start_link([h|t] = params, opts) do
        GenServer.start_link(__MODULE__,
          [parent: params[:parent],
           name: params[:name],
           topic: params[:topic],
           meta: params[:meta],
           passthrough: params[:passthrough],
           event_manager: opts[:event_manager],
           definitions: opts[:definitions]])
      end

      def evaluate(pid, %Intent{} = intent) do
        GenServer.cast(pid, {:evaluate, intent})
      end

      def name(pid), do: GenServer.call(pid, :specie_name)

      # overridable delegates

      def handle_intent(%Intent{} = intent, %{topic: nil, meta: nil} = state) do
        # case IntentionProvider.intention(String.to_atom intent.name) do
        case state.definitions.intention(String.to_atom intent.name) do
          {:error, reason} ->
            GenEvent.notify(state.event_manager,
              %Reaction{about: :undefined_intention, trigger: intent})
            {:error, :no_intention}

          {:ok, intention} ->
            GenEvent.notify(state.event_manager,
              %Reaction{about: :begin_topic, trigger: intent})

            Process.flag(:trap_exit, true)

            {:ok, topic} = Topic.start_link(intent, [definitions: state.definitions])

            case Topic.forward(topic) do
              {:question, question} ->
                GenEvent.notify(state.event_manager,
                  %Reaction{about: :question, text: question})
                {:topic_output, %{topic: topic}}

              {:completed, features} ->
                intent = Topic.intent(topic)

                if meta_dialog?(state.name) do
                  GenServer.cast(state.parent,
                    {:meta, %{intent: intent,
                              features: features,
                              passthrough: state.passthrough}})
                else
                  GenEvent.notify(state.event_manager,
                    %Reaction{about: :completed,
                              text: "root dialog completed!",
                              trigger: intent, features: features})
                end
                {:topic_end, :completed}
            end
        end
      end
      def handle_intent(%Intent{} = intent, %{meta: nil} = state) do
        GenEvent.notify(Dobar.DialogEvents,
          %Reaction{about: :continue_topic, trigger: intent})

        case Topic.forward(state.topic, intent) do
          {:question, question} ->
            GenEvent.notify(DialogEvents, %Reaction{about: :question, text: question})
            {:topic_output, nil}

          {:completed, features} ->
            topic_intent = Topic.intent(state.topic)
            if root_dialog?(state.name) do
              GenEvent.notify(DialogEvents,
                %Reaction{about: :completed,
                          text: "dialog completed!",
                          trigger: topic_intent, features: features})
            end
            if meta_dialog?(state.name) do
              GenServer.cast(state.parent,
                {:meta, %{intent: topic_intent,
                          features: features,
                          passthrough: state.passthrough}})
            end
            {:topic_end, :completed}

          {:nomatch, topic_intent} ->
            GenEvent.notify(DialogEvents,
              %Reaction{about: :intent_no_match,
                        trigger: intent,
                        other: %{dialog_intent: topic_intent}})

            alternative =
              intent.name
              |> String.to_atom
              |> find_alternative(topic_intent)
              |> validate_confidence(intent)
              |> validate_inception(topic_intent)

            case alternative do
              {:reference, intention_name} ->
                Process.flag(:trap_exit, true)

                GenEvent.notify(Dobar.DialogEvents,
                  %Reaction{about: :alternative_reference_found, trigger: intent})

                # dialog = Dobar.Dialog.Species.Routes.specie intention_name
                dialog = SpeciesRoutes.specie intention_name
                {:ok, pid} = dialog.start_link([parent: self, name: intention_name])
                dialog.evaluate(pid, intent)

                {:topic_alternative, %{meta: pid}}

              {:alternative, intention_name} ->
                Process.flag(:trap_exit, true)

                GenEvent.notify(Dobar.DialogEvents,
                  %Reaction{about: :alternative_meta_found, trigger: intent})

                switch_intent = %Intent{name: "switch_conversation",
                                        confidence: 1,
                                        input: "confirm your shit"}

                # dialog = Dobar.Dialog.Species.Routes.specie(intention_name)
                dialog = SpeciesRoutes.specie(intention_name)
                {:ok, pid} = dialog.start_link([name: String.to_existing_atom(switch_intent.name),
                                                parent: self,
                                                passthrough: intent])

                dialog.evaluate(pid, switch_intent)

                {:topic_alternative, %{meta: pid}}

              {:noalternative, intention_name} ->
                GenEvent.notify(DialogEvents,
                  %Reaction{about: :no_alternative_found, trigger: intent})
                {:topic_nomatch, intention_name}

              {:samealternative, intention_name} ->
                GenEvent.notify(Dobar.DialogEvents,
                  %Reaction{about: :same_alternative_found, trigger: intent})
                {:topic_nomatch, intention_name}
            end
        end
      end

      def handle_meta(%{intent: %{name: "cancel_command"}} = meta, state) do
        case meta.features do
          %{approve: %{matched: :confirm}} ->
            if meta_dialog?(state.name),
              do: GenServer.cast(state.parent, {:meta, :canceled})

            if root_dialog?(state.name),
              do: GenEvent.notify(DialogEvents,
                    %Reaction{about: :canceled,
                              text: "dialog completed!",
                              trigger: meta.intent, features: meta.features})
            {:topic_end, :completed}

          %{approve: %{matched: :infirm}} ->
            case Topic.forward(state.topic) do
              {:question, question} ->
                GenEvent.notify(DialogEvents, %Reaction{about: :question, text: question})
                {:topic_output, %{meta: nil}}
              {:completed, features} ->
                GenEvent.notify(DialogEvents, %Reaction{about: :completed, text: "ok"})
                {:topic_end, :completed}
            end
        end
      end
      def handle_meta(%{intent: %{name: "switch_conversation"}} = meta, state) do
        case meta.features do
          %{approve: %{matched: :confirm}} ->
            if meta_dialog?(state.name) do
              GenServer.cast(state.parent, {:meta, meta})
            else
              GenEvent.notify(DialogEvents,
                %Reaction{about: :switch_conversation,
                          text: "switch the conversation",
                          trigger: meta.passthrough})
            end
            {:topic_end, :completed}

          %{approve: %{matched: :infirm}} ->
            case Topic.forward(state.topic) do
              {:question, question} ->
                GenEvent.notify(DialogEvents, %Reaction{about: :question, text: question})
                {:topic_output, %{meta: nil}}

              # It could be a bug if this will ever match, because it should be
              # impossible to try to switch to a new conversation while the
              # dialog has already been completed(or the state is broken!)
              {:completed, features} ->
                GenEvent.notify(DialogEvents, %Reaction{about: :completed, text: "ok"})
                {:topic_end, :completed}
            end
        end
      end
      def handle_meta(%{intent: %{name: "change_field"}} = meta, state) do
        case meta.features do
          %{approve: %{matched: :confirm}} ->
            intent = %Intent{name: "purge_change_fields",
                             entities: meta.intent.entities,
                             confidence: 1}

            # dialog = Dobar.Dialog.Species.Routes.specie(intent.name)
            dialog = SpeciesRoutes.specie(intent.name)
            {:ok, pid} = dialog.start_link([name: intent.name, parent: self])
            dialog.evaluate(pid, intent)

            {:topic_output, %{meta: pid}}

          %{approve: %{matched: :infirm}} ->
            case Topic.forward(state.topic) do
              {:question, question} ->
                GenEvent.notify(DialogEvents, %Reaction{about: :question, text: question})
                {:topic_output, %{meta: nil}}

              {:completed, features} ->
                GenEvent.notify(DialogEvents, %Reaction{about: :completed, text: "ok"})
                {:topic_end, :completed}
            end
        end
      end
      def handle_meta(%{intent:  %{name: "purge_change_fields"}} = meta, state) do
        carried_entities =
          meta.features
          |> Map.values
          |> Enum.map(fn item ->
            slots_values =
              item.value
              |> Enum.map(&(%{confidence: 1, type: "value", value: &1}))
            entity = Map.put(%{}, List.first(item.slots), slots_values)
          end)
          |> List.foldl(%{}, fn item, acc -> Map.merge(acc, item) end)

        carrier_intent = %Intent{name: "carrier_bearer", entities: carried_entities}

        case Topic.forward(state.topic, carrier_intent) do
          {:question, question} ->
            GenEvent.notify(DialogEvents, %Reaction{about: :question, text: question})
            {:topic_output, %{meta: nil}}
          {:completed, features} ->
            GenEvent.notify(DialogEvents, %Reaction{about: :completed, text: "ok"})
            {:topic_end, :completed}
        end
      end
      def handle_meta(:canceled, state) do
        case Topic.forward(state.topic) do
          {:question, question} ->
            GenEvent.notify(DialogEvents, %Reaction{about: :question, text: question})
            {:topic_output, %{meta: nil}}
          {:completed, features} ->
            GenEvent.notify(DialogEvents, %Reaction{about: :completed, text: "ok"})
            {:topic_end, :completed}
        end
      end

      defoverridable [handle_intent: 2, handle_meta: 2]

      # callbacks

      def init([h|t] = args) do
        {:ok, %{name: args[:name],
                topic: args[:topic],
                meta: args[:meta],
                parent: args[:parent],
                passthrough: args[:passthrough],
                event_manager: args[:event_manager],
                definitions: args[:definitions]}}
      end

      def handle_call(:topic_capabilities, _from, %{topic: topic} = state) do
        {:reply, Topic.capabilities(topic), state}
      end

      def handle_cast({:evaluate, intent}, %{topic: topic, meta: nil} = state) do
        case handle_intent(intent, state) do
          {:topic_output, nil} ->
            {:noreply, state}

          {:topic_output, some_state} ->
            {:noreply, Map.merge(state, some_state)}

          {:topic_end, :completed} ->
            {:stop, :normal, nil}

          {:topic_alternative, some_state} ->
            {:noreply, Map.merge(state, some_state)}

          {:topic_nomatch, _} ->
            {:noreply, state}

          {:error, :no_intention} ->
            {:noreply, state}

          {:error, :meta_as_root} ->
            {:stop, :normal, nil}

          {:error, :purge_nomatches} ->
            {:stop, :normal, nil}
        end
      end
      def handle_cast({:evaluate, intent}, %{meta: meta, parent: parent} = state) do
        # the dialog has a meta chain so proxy the call until the last meta-dialog
        GenServer.cast(meta, {:evaluate, intent})
        {:noreply, state}
      end
      def handle_cast({:meta, %{} = meta}, state) do
        case handle_meta(meta, state) do
          {:topic_output, some_state} ->
            {:noreply, Map.merge(state, some_state)}
          {:topic_end, :completed} ->
            {:stop, :normal, nil}
        end
      end
      def handle_cast({:meta, :canceled}, state) do
        case handle_meta(:canceled, state) do
          {:topic_output, some_state} ->
            {:noreply, Map.merge(state, some_state)}
          {:topic_end, :completed} ->
            {:stop, :normal, nil}
        end
      end

      # private

      defp root_dialog?(name), do: name == :root_dialog

      defp meta_dialog?(name), do: !root_dialog?(name)

      defp find_alternative(intention_name, dialog_intent) do
        capability_name = intention_name
        topic_intent_name = dialog_intent.name |> String.to_atom

        # extract the intention for the current topic
        {:ok, intention} = IntentionProvider.intention(topic_intent_name)

        # extract the capabilities of the current topic
        topic_capabilities = intention[topic_intent_name][capability_name]

        # it searches first inside the current topic's capabilities and if
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
            {:reference, intention_name}
          nil ->
            case IntentionProvider.intention(capability_name) do
              {:ok, intention} ->
                topic_capabilities = intention[capability_name]
                # if the capability is contextual and applies only for meta, stop
                # searching the global registry - no intention capability found!
                if topic_capabilities[:relationship] == :meta do
                  {:noalternative, intention_name}
                else
                  {:alternative, intention_name}
                end
              {:error, _reason} ->
                {:noalternative, intention_name}
            end
        end
      end

      defp validate_confidence({:reference, intention_name}, input_intent) do
        case input_intent do
          %{confidence: conf} when conf > @confidence_treshold ->
            {:reference, intention_name}
          _ ->
            {:noalternative, intention_name}
        end
      end
      defp validate_confidence({:alternative, intention_name}, input_intent) do
        case input_intent do
          %{confidence: conf} when conf > @confidence_treshold ->
            {:alternative, intention_name}
          _ ->
            {:noalternative, intention_name}
        end
      end
      defp validate_confidence({:noalternative, intention_name}, _) do
        {:noalternative, intention_name}
      end

      # tests whether the input intent is the same as the current intent
      defp validate_inception({:alternative, intention_name}, input_intent) do
        cond do
          intention_name == String.to_existing_atom(input_intent.name) ->
            {:samealternative, intention_name}
          true ->
            {:alternative, intention_name}
        end
      end
      defp validate_inception(current, _input_intent), do: current
    end
  end
end
