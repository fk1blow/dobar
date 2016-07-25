defmodule Dobar.Conversation.Dialog do
  use GenServer

  alias Dobar.Model.Reaction
  alias Dobar.Model.Intent
  alias Dobar.Conversation.Intention.Provider, as: IntentionProvider

  @confidence_treshold 0.75

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
  Handles the intent evaluation when there is no active dialog yet
  It also creates a new dialog and starts it - by invoking `continue`.
  """
  def handle_cast({:evaluate, intent}, %{topic: nil, meta: nil} = state) do
    IO.puts "begin topic"

    {:ok, topic} = Dobar.Conversation.Topic.start_link(intent)

    case Dobar.Conversation.Topic.react(topic) do
      %Reaction{type: :question} = reaction ->
        IO.puts "reaction type: #{inspect reaction.type}"
        IO.puts "reaction features: #{inspect reaction.features}"
        IO.puts "________________________________________________"
        {:noreply, Map.merge(state, %{topic: topic})}
      %Reaction{type: :completed} = reaction ->
        IO.puts "reaction type: #{inspect reaction.type}"
        IO.puts "reaction features: #{inspect reaction.features}"
        {:stop, :normal, nil}
    end
  end

  @doc """
  Handles the intent evaluation when a topic already exist but not a meta.
  """
  def handle_cast({:evaluate, intent}, %{topic: topic, meta: nil} = state) do
    IO.puts "continue topic: #{inspect intent}"

    case Dobar.Conversation.Topic.react(topic, intent) do
      %Reaction{type: :question} = reaction ->
        IO.puts "reaction type: #{inspect reaction.type}"
        IO.puts "reaction features: #{inspect reaction.features}"
        IO.puts "________________________________________________"
        {:noreply, %{topic: topic, meta: nil, parent: state.parent}}

      %Reaction{type: :completed} = reaction ->
        IO.puts "reaction type: #{inspect reaction.type}"
        IO.puts "reaction features: #{inspect reaction.features}"

        if not_root?(self) do
          IO.puts "ending topic, intent: #{inspect intent}"
          IO.puts "end state: #{inspect state}"
          send state.parent, {:meta, reaction}
        end

        {:stop, :normal, nil}

      %Reaction{type: :nomatch} = reaction ->
        IO.puts "cannot match"
        IO.puts "reaction type: #{inspect reaction.type}"
        IO.puts "reaction features: #{inspect reaction.features}"

        case find_alternative(intent, topic) |> validate_alternative(intent) do
          {:reference, intention} ->
            IO.puts "reference found: #{inspect intention}"

            Process.flag(:trap_exit, true)

            {:ok, pid} = Dobar.Conversation.Dialog.start_link self, intention
            Dobar.Conversation.Dialog.evaluate pid, intent

            {:noreply, Map.merge(state, %{meta: pid})}

          {:alternative, intention} ->
            IO.puts "alternative dialog: #{inspect intention}"

            Process.flag(:trap_exit, true)

            {:ok, pid} = Dobar.Conversation.Dialog.start_link self, intention
            switch_intent = %Intent{name: "switch_conversation",
                                    confidence: 1,
                                    input: "confirm your shit"}
            Dobar.Conversation.Dialog.evaluate pid, switch_intent

            {:noreply, Map.merge(state, %{meta: pid})}

          {:noalternative, intention} ->
            IO.puts "no alternative found: #{inspect intention}"
            {:noreply, state}
        end
    end
  end

  @doc """
  Handles the intent evaluation when a meta exists, passing/delegating the conversation
  to the meta dialog process.
  """
  def handle_cast({:evaluate, intent}, %{meta: meta} = state) do
    Dobar.Conversation.Dialog.evaluate meta, intent
    {:noreply, state}
  end

  @doc """
  If the reaction is %{confirm: "yes"}, then it sends a message to the parent,
  telling him to continue its Dialog, or if %{infirm: "no"} just continue
  with the Dialog it has active
  """
  def handle_info({:meta, %{intent: %{name: "cancel_command"}} = reaction}, state) do
    IO.puts "meta ended"
    IO.puts "reaction from meta: #{inspect reaction}"

    case reaction do
      %{features: %{confirm: "yes"}} ->
        IO.puts "ok, kill this dialog"

        if not_root?(self) do
          send(state.parent, {:meta, :continue})
        end
        {:stop, :normal, nil}

      %{features: %{infirm: "no"}} ->
        IO.puts "no, continue with the dialog"

        case Dobar.Conversation.Topic.react(state.topic) do
          %Reaction{type: :question} = reaction ->
            IO.puts "reaction type: #{inspect reaction.type}"
            IO.puts "reaction features: #{inspect reaction.features}"
            IO.puts "________________________________________________"
            {:noreply, Map.merge(state, %{meta: nil})}
          %Reaction{type: :completed} = reaction ->
            IO.puts "wahaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaout"
            IO.puts "reaction type: #{inspect reaction.type}"
            IO.puts "reaction features: #{inspect reaction.features}"
            {:stop, :normal, nil}
        end
    end
  end

  # TODO: not finished; should complete the confirmation callback for infirm or confirm
  def handle_info({:meta, %{intent: %{name: "switch_conversation"}} = reaction}, state) do
    IO.puts "meta ended"
    IO.puts "reaction from meta: #{inspect reaction}"

    case reaction do
      %{features: %{confirm: "yes"}} ->
        IO.puts "ok, kill this (alternative)dialog"
        # If it's the root dialog, just send this away(to an event handler,
        # at some point), else send the meta to the parent(chain)
        if root_dialog?(self) do
          IO.puts "ROOT: should do something with this alternative-reaction dialog"
        else
          send(state.parent, {:meta, reaction})
        end
        {:stop, :normal, nil}

      %{features: %{infirm: "no"}} ->
        IO.puts "no, continue with the dialog"

        case Dobar.Conversation.Topic.react(state.topic) do
          %Reaction{type: :question} = reaction ->
            IO.puts "reaction type: #{inspect reaction.type}"
            IO.puts "reaction features: #{inspect reaction.features}"
            IO.puts "________________________________________________"
            {:noreply, Map.merge(state, %{meta: nil})}
          %Reaction{type: :completed} = reaction ->
            IO.puts "wahaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaout"
            IO.puts "reaction type: #{inspect reaction.type}"
            IO.puts "reaction features: #{inspect reaction.features}"
            {:stop, :normal, nil}
        end
    end
  end

  def handle_info({:meta, :continue}, state) do
    IO.puts "meta died! should continue with the dialog"

    case Dobar.Conversation.Topic.react(state.topic) do
      %Reaction{type: :question} = reaction ->
        IO.puts "reaction type: #{inspect reaction.type}"
        IO.puts "reaction features: #{inspect reaction.features}"
        IO.puts "________________________________________________"
        {:noreply, Map.merge(state, %{meta: nil})}
      %Reaction{type: :completed} = reaction ->
        IO.puts "reaction type: #{inspect reaction.type}"
        IO.puts "reaction features: #{inspect reaction.features}"
        {:stop, :normal, nil}
    end
  end

  # TODO: to be defined and expressed inside the main flow concept
  def handle_info({:EXIT, _from ,reason}, state) do
    IO.puts "EXIIIIIIIIIIIIIIIIT: #{inspect reason}"
    {:noreply, state}
  end

  # private utils
  #

  defp find_alternative(intent, topic) do
    capability_name = String.to_atom intent.name
    topic_intent = Dobar.Conversation.Topic.intent(topic)
    topic_intent_name = String.to_atom topic_intent.name

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
        IO.puts "topic_capabilities: #{inspect topic_capabilities}"
        IO.puts "capability_name: #{inspect capability_name}"

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

  # defp alternative_meta?

  defp not_root?(pid), do: root_dialog?(pid) == false

  defp root_dialog?(pid), do: pid == Process.whereis :root_dialog
end
