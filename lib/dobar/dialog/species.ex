defmodule Dobar.Dialog.Species do
  defmacro __using__(_opts) do
    quote do
      use GenServer

      alias Dobar.Reaction
      alias Dobar.Intent
      alias Dobar.Dialog.Meta
      alias Dobar.Dialog.Topic
      alias Dobar.Dialog.Species.Routes, as: SpeciesRoutes
      alias Dobar.Dialog.Alternative

      @confidence_treshold 0.8

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
        with {:ok, _}   <- state.definitions.intention(String.to_atom intent.name),
             :confident <- validate_confidence(intent)
          do
            {:ok, topic} = Topic.start_link(intent, [definitions: state.definitions])
            case Topic.forward(topic) do
              {:question, question} ->
                GenEvent.notify(state.event_manager,
                  %Reaction{about: :question, text: question, trigger: intent})
                {:topic_output, %{topic: topic}}

              {:completed, features} ->
                intent = Topic.intent(topic)

                if meta_dialog?(state.name) do
                  GenServer.cast(state.parent,
                    {:meta, %Meta{intent: intent,
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
          else
            :unconfident ->
              GenEvent.notify(state.event_manager,
                %Reaction{about: :low_confidence_intent, trigger: intent})
              {:error, :no_intention}

            {:nodefinition, reason} ->
              GenEvent.notify(state.event_manager,
                %Reaction{about: :undefined_intention, trigger: intent})
              {:error, :no_intention}
          end
      end
      def handle_intent(%Intent{} = intent, %{meta: nil} = state) do
        GenEvent.notify(state.event_manager,
          %Reaction{about: :continue_topic, trigger: intent})

        case Topic.forward(state.topic, intent) do
          {:question, question} ->
            GenEvent.notify(state.event_manager,
              %Reaction{about: :question, text: question, trigger: intent})
            {:topic_output, nil}

          {:completed, features} ->
            topic_intent = Topic.intent(state.topic)
            if root_dialog?(state.name) do
              GenEvent.notify(state.event_manager,
                %Reaction{about: :completed,
                          text: "dialog completed!",
                          trigger: topic_intent, features: features})
            end
            if meta_dialog?(state.name) do
              GenServer.cast(state.parent,
                {:meta, %Meta{intent: topic_intent,
                          features: features,
                          passthrough: state.passthrough}})
            end
            {:topic_end, :completed}

          {:nomatch, topic_intent} ->
            GenEvent.notify(state.event_manager,
              %Reaction{about: :intent_no_match,
                        trigger: intent,
                        other: %{dialog_intent: topic_intent}})

            case Alternative.dialog(state.definitions, topic_intent, intent) do
              {:reference, intention_name} ->
                Process.flag(:trap_exit, true)

                GenEvent.notify(state.event_manager,
                  %Reaction{about: :alternative_reference_found, trigger: intent})

                dialog = SpeciesRoutes.specie intention_name
                {:ok, pid} = dialog.start_link(
                  [parent: self, name: intention_name],
                  [definitions: state.definitions, event_manager: state.event_manager])

                dialog.evaluate(pid, intent)

                {:topic_alternative, %{meta: pid}}

              {:alternative, intention_name} ->
                Process.flag(:trap_exit, true)

                GenEvent.notify(state.event_manager,
                  %Reaction{about: :alternative_meta_found, trigger: intent})

                switch_intent = %Intent{name: "switch_conversation",
                                        confidence: 1,
                                        input: "confirm your shit"}

                dialog = SpeciesRoutes.specie(intention_name)
                {:ok, pid} = dialog.start_link(
                  [name: String.to_existing_atom(switch_intent.name),
                   parent: self,
                   passthrough: intent],
                  [definitions: state.definitions, event_manager: state.event_manager])

                dialog.evaluate(pid, switch_intent)

                {:topic_alternative, %{meta: pid}}

              {:noalternative, intention_name} ->
                GenEvent.notify(state.event_manager,
                  %Reaction{about: :no_alternative_found, trigger: intent})
                {:topic_nomatch, intention_name}

              {:samealternative, intention_name} ->
                GenEvent.notify(state.event_manager,
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
              do: GenEvent.notify(state.event_manager,
                    %Reaction{about: :canceled,
                              text: "dialog completed!",
                              trigger: meta.intent,
                              features: meta.features})
            {:topic_end, :completed}

          %{approve: %{matched: :infirm}} ->
            case Topic.forward(state.topic) do
              {:question, question} ->
                GenEvent.notify(state.event_manager,
                  %Reaction{about: :question, text: question})
                {:topic_output, %{meta: nil}}

              {:completed, features} ->
                GenEvent.notify(state.event_manager,
                  %Reaction{about: :completed, text: "ok"})
                {:topic_end, :completed}
            end
        end
      end
      def handle_meta(%{intent: %{name: "switch_conversation"}} = meta, state) do
        case meta.features do
          %{approve: %{matched: :confirm}} ->
            if root_dialog?(state.name) do
              GenEvent.notify(state.event_manager,
                %Reaction{about: :switch_conversation,
                          text: "switch the conversation",
                          trigger: meta.passthrough})
            else
              GenServer.cast(state.parent, {:meta, meta})
            end
            {:topic_end, :completed}

          %{approve: %{matched: :infirm}} ->
            case Topic.forward(state.topic) do
              {:question, question} ->
                GenEvent.notify(state.event_manager, %Reaction{about: :question, text: question})
                {:topic_output, %{meta: nil}}

              # It could be a bug if this will ever match, because it should be
              # impossible to try to switch to a new conversation while the
              # dialog has already been completed(or the state is broken!)
              {:completed, features} ->
                GenEvent.notify(state.event_manager, %Reaction{about: :completed, text: "ok"})
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
            {:ok, pid} = dialog.start_link(
              [name: intent.name, parent: self],
              [definitions: state.definitions, event_manager: state.event_manager])
            dialog.evaluate(pid, intent)

            {:topic_output, %{meta: pid}}

          %{approve: %{matched: :infirm}} ->
            case Topic.forward(state.topic) do
              {:question, question} ->
                GenEvent.notify(state.event_manager, %Reaction{about: :question, text: question})
                {:topic_output, %{meta: nil}}

              {:completed, features} ->
                GenEvent.notify(state.event_manager, %Reaction{about: :completed, text: "ok"})
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
            GenEvent.notify(state.event_manager, %Reaction{about: :question, text: question})
            {:topic_output, %{meta: nil}}
          {:completed, features} ->
            GenEvent.notify(state.event_manager, %Reaction{about: :completed, text: "ok"})
            {:topic_end, :completed}
        end
      end
      def handle_meta(:canceled, state) do
        case Topic.forward(state.topic) do
          {:question, question} ->
            GenEvent.notify(state.event_manager, %Reaction{about: :question, text: question})
            {:topic_output, %{meta: nil}}
          {:completed, features} ->
            GenEvent.notify(state.event_manager, %Reaction{about: :completed, text: "ok"})
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
      def handle_cast({:meta, %Meta{} = meta}, state) do
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

      defp validate_confidence(%Intent{confidence: confidence}) do
        case confidence > @confidence_treshold do
          true -> :confident
          false -> :unconfident
        end
      end
    end
  end
end
