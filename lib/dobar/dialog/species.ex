defmodule Dobar.Dialog.Species do
  defmacro __using__(_opts) do
    quote do
      use GenServer

      alias Dobar.Reaction, as: Reaction
      alias Dobar.Model.Intent
      alias Dobar.Dialog.Topic
      alias Dobar.Conversation.Intention.Provider, as: IntentionProvider

      alias Dobar.DialogEvents

      @confidence_treshold 0.8

      # Public interface

      def start_link(:root_dialog) do
        GenServer.start_link __MODULE__, [name: :root_dialog], name: :root_dialog
      end
      # TODO: add `name` as process register only if opts[:name] exists
      def start_link([h|t] = opts) do
        GenServer.start_link(__MODULE__,
          [parent: opts[:parent],
           name: opts[:name],
           passthrough: opts[:passthrough]])
      end

      def evaluate(pid, %Intent{} = intent) do
        GenServer.cast(pid, {:evaluate, intent})
      end

      # overridable delegates

      def handle_intent(%Intent{} = intent, %{topic: nil, meta: nil} = state) do
        case IntentionProvider.intention(String.to_atom intent.name) do
          {:error, reason} ->
            GenEvent.notify(Dobar.DialogEvents,
              %Reaction{about: :undefined_intention, data: %{intent: intent}})
            {:error, :no_intention}

          {:ok, intention} ->
            GenEvent.notify(Dobar.DialogEvents,
              %Reaction{about: :begin_topic, data: %{intent: intent}})

            Process.flag(:trap_exit, true)

            {:ok, topic} = Topic.start_link intent

            case Topic.react(topic) do
              {:question, question} ->
                GenEvent.notify(DialogEvents, %Reaction{about: :question, text: question})
                {:topic_output, %{topic: topic}}

              # {:completed, intent, features} ->
              {:completed, features} ->
                intent = Topic.intent(topic)

                if meta_dialog?(self) do
                  GenServer.cast(state.parent,
                    {:meta, %{intent: intent,
                              features: features,
                              passthrough: state.passthrough}})
                else
                  GenEvent.notify(DialogEvents,
                    %Reaction{about: :completed,
                              text: "root dialog completed!",
                              data: %{intent: intent, features: features}})
                end
                {:topic_end, :completed}
            end
        end
      end
      def handle_intent(%Intent{} = intent, %{topic: topic, meta: nil} = state) do
        GenEvent.notify(Dobar.DialogEvents,
          %Reaction{about: :continue_topic, data: %{topic: topic, intent: intent}})

        case Topic.react(topic, intent) do
          {:question, question} ->
            GenEvent.notify(DialogEvents, %Reaction{about: :question, text: question})
            {:topic_output, nil}

          {:completed, features} ->
            intent = Topic.intent(topic)

            GenEvent.notify(DialogEvents,
              %Reaction{about: :completed,
                        text: "dialog completed!",
                        data: %{intent: intent, features: features}})

            if meta_dialog?(self) do
              GenServer.cast(state.parent,
                {:meta, %{intent: intent,
                          features: features,
                          passthrough: state.passthrough}})
            end
            {:topic_end, :completed}

          {:nomatch, topic_intent} ->
            GenEvent.notify(DialogEvents, %Reaction{about: :intent_no_match, data: {topic}})

            alternative =
              intent.name
              |> String.to_atom
              |> find_alternative(topic_intent)
              |> validate_confidence(topic_intent)
              |> validate_inception(topic_intent)

            case alternative do
              {:reference, intention_name} ->
                Process.flag(:trap_exit, true)

                GenEvent.notify(Dobar.DialogEvents,
                  %Reaction{about: :alternative_reference_found, data: %{intent: intent}})

                dialog = Dobar.Dialog.Species.Routes.specie intention_name

                {:ok, pid} = dialog.start_link([parent: self, name: intention_name])
                dialog.evaluate(pid, intent)

                {:topic_alternative, %{meta: pid}}

              {:alternative, intention_name} ->
                Process.flag(:trap_exit, true)

                GenEvent.notify(Dobar.DialogEvents,
                  %Reaction{about: :alternative_meta_found, data: %{intent: intent}})

                switch_intent = %Intent{name: "switch_conversation",
                                        confidence: 1,
                                        input: "confirm your shit"}

                dialog = Dobar.Dialog.Species.Routes.specie(intention_name)
                {:ok, pid} = dialog.start_link([name: String.to_existing_atom(switch_intent.name),
                                                parent: self,
                                                passthrough: intent])

                dialog.evaluate(pid, switch_intent)

                {:topic_alternative, %{meta: pid}}

              {:noalternative, intention_name} ->
                GenEvent.notify(DialogEvents,
                  %Reaction{about: :no_alternative_found, data: %{intent: intent}})
                {:topic_nomatch, intention_name}

              {:samealternative, intention_name} ->
                GenEvent.notify(Dobar.DialogEvents,
                  %Reaction{about: :same_alternative_found, data: %{intent: intent}})
                {:topic_nomatch, intention_name}
            end
        end
      end

      def handle_meta(%{intent: %{name: "cancel_command"}} = meta, state) do
        case meta.features do
          %{approve: %{entity: :confirm}} ->
            if meta_dialog?(self) do
              GenServer.cast(state.parent, {:meta, :canceled})
            end
            {:topic_end, :completed}
          %{approve: %{entity: :infirm}} ->
            case Topic.react(state.topic) do
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
          %{approve: %{entity: :confirm}} ->
            if meta_dialog?(self) do
              GenServer.cast(state.parent, {:meta, meta})
            else
              GenEvent.notify(DialogEvents,
                %Reaction{about: :switch_conversation,
                          text: "switch the conversation",
                          data: %{passthrough: meta.passthrough}})
            end
            {:topic_end, :completed}

          %{approve: %{entity: :infirm}} ->
            case Topic.react(state.topic) do
              {:question, question} ->
                GenEvent.notify(DialogEvents, %Reaction{about: :question, text: question})
                {:topic_output, %{meta: nil}}

              # It could be a bug if this will ever match, because it should be
              # impossible to try to switch to a new conversation while the
              # dialog has already been completed(or the state is broken!)
              # %Reaction{type: :completed} = reaction ->
              {:completed, features} ->
                GenEvent.notify(DialogEvents, %Reaction{about: :completed, text: "ok"})
                {:topic_end, :completed}
            end
        end
      end
      def handle_meta(%{intent: %{name: "change_field"}} = meta, state) do
        case meta.features do
          %{approve: %{entity: :confirm}} ->
            intent = %Intent{name: "purge_change_fields",
                             entities: meta.intent.entities,
                             confidence: 1}

            dialog = Dobar.Dialog.Species.Routes.specie(intent.name)
            {:ok, pid} = dialog.start_link([name: intent.name, parent: self])
            dialog.evaluate(pid, intent)

            {:topic_output, %{meta: pid}}

          %{approve: %{entity: :infirm}} ->
            case Topic.react(state.topic) do
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
        case Topic.react(state.topic, carrier_bearer(meta.features)) do
          {:question, question} ->
            GenEvent.notify(DialogEvents, %Reaction{about: :question, text: question})
            {:topic_output, %{meta: nil}}

          {:completed, features} ->
            GenEvent.notify(DialogEvents, %Reaction{about: :completed, text: "ok"})
            {:topic_end, :completed}
        end
      end
      def handle_meta(:canceled, state) do
        case Topic.react(state.topic) do
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

      def init(:root_dialog) do
        {:ok, %{name: :root_dialog,
                topic: nil,
                meta: nil,
                parent: nil,
                passthrough: nil}}
      end
      def init([h|t] = args) do
        {:ok, %{name: args[:name],
                topic: nil,
                meta: nil,
                parent: args[:parent],
                passthrough: args[:passthrough]}}
      end

      def handle_call(:topic_capabilities, _from, %{topic: topic} = state) do
        {:reply, Topic.capabilities(topic), state}
      end

      def handle_cast({:evaluate, intent}, %{topic: topic, meta: nil} = state) do
        case handle_intent intent, state do
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

      defp root_dialog?(pid), do: pid == Process.whereis :root_dialog
      defp meta_dialog?(pid), do: !root_dialog?(pid)

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

      defp carrier_bearer(features) do
        entities =
          features
          |> Map.keys
          |> Enum.map(fn x ->
            field_name = Map.get(features, x).entity
            {field_name, %{confidence: 1, type: "value", value: Map.get(features, x).value}}
          end)
          |> List.foldl(%{}, fn x, acc ->
            field_map = Map.put(%{}, elem(x, 0), [elem(x, 1)])
            Map.merge(acc, field_map)
          end)

        %Intent{name: "carrier_bearer", entities: entities}
      end
    end
  end
end
