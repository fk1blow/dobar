defmodule Dobar.Dialog.Alternative do
  @confidence_treshold 0.8

  @type alternative :: {:reference, String.t} |
                       {:alternative, String.t} |
                       {:noalternative, String.t} |
                       {:samealternative, String.t}

  @spec dialog(term, Intent.t, Intent.t) :: alternative
  def dialog(definitions, topic_intent, trigger_intent) do
    trigger_intent
    |> Map.get(:name)
    |> String.to_atom
    |> find_alternative(topic_intent, definitions)
    |> validate_confidence(trigger_intent)
    |> validate_inception(topic_intent)
  end

  defp find_alternative(intention_name, dialog_intent, definitions) do
    capability_name = intention_name
    topic_intent_name = dialog_intent.name |> String.to_atom

    # extract the intention for the current topic
    {:ok, intention} = definitions.intention(topic_intent_name)

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
        case definitions.intention(capability_name) do
          {:ok, intention} ->
            topic_capabilities = intention[capability_name]
            # if the capability is contextual and applies only for meta, stop
            # searching the global registry - no intention capability found!
            if topic_capabilities[:relationship] == :meta do
              {:noalternative, intention_name}
            else
              {:alternative, intention_name}
            end
          {:nodefinition, _reason} ->
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
