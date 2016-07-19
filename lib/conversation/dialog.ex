defmodule Dobar.Conversation.Dialog do
  use GenServer

  alias Dobar.Model.Intent
  alias Dobar.Conversation.Intention.Provider, as: IntentionProvider

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

  # def complete(pid, topic) do
  #   GenServer.cast pid, {:complete, topic}
  # end

  # def continue(pid) do
  #   GenServer.cast pid, :continue
  # end

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
    IO.puts "begin topic, intent"

    {:ok, topic} = Dobar.Conversation.Topic.start_link(intent)
    IO.puts "topic: #{inspect topic}"

    case Dobar.Conversation.Topic.react(topic) do
      {:topic, question}   ->
        IO.puts "Topic: question #{inspect question}"
        IO.puts "________________________________________________"
      {:completed, topics} ->
        IO.puts "The topic has been completed; topics: #{inspect topics}"
    end

    {:noreply, Map.merge(state, %{topic: topic})}
  end

  @doc """
  Handles the intent evaluation when a topic already exist but not a meta.
  """
  def handle_cast({:evaluate, intent}, %{topic: topic, meta: nil} = state) do
    IO.puts "continue topic: #{inspect intent}"

    case Dobar.Conversation.Topic.react(topic, intent) do
      {:next, outcome} ->
        IO.puts "Topic: question #{inspect outcome.question}"
        IO.puts "________________________________________________"
        {:noreply, %{topic: topic, meta: nil, parent: state.parent}}

      # TODO: the completed should also be an outcome of the topic, regardless
      # of its lifecycle/internals
      {:completed, topic} ->
        IO.puts "The topic has been completed with: #{inspect topic}"

        if not_root?(self) do
          IO.puts "ending topic, intent: #{inspect intent}"
          IO.puts "end state: #{inspect state}"
          # use direct calls to the referer(parent) instead
          # Dobar.Conversation.Dialog.complete(state.parent, topic)
        end

        {:stop, :normal, nil}

      {:nomatch, reason} ->
        IO.puts "cannot match: #{inspect reason}"

        case alternative(intent, topic) do
          {:reference, intention} ->
            IO.puts "reference found: #{inspect intention}"

          {:alternative, intention} ->
            IO.puts "alternative found: #{inspect intention}"
            IO.puts "alternative for intent: #{inspect intent}"

            Process.flag(:trap_exit, true)

            {:ok, pid} = Dobar.Conversation.Dialog.start_link self, intention
            switch_intent = %Intent{name: "confirmation", confidence: 1, input: "confirm your shit"}
            Dobar.Conversation.Dialog.evaluate pid, switch_intent

            {:noreply, Map.merge(state, %{meta: pid})}

          {:noalternative, intention} ->
            IO.puts "no alternative found: #{inspect intention}"
            {:noreply, %{topic: topic, meta: nil, parent: state.parent}}
        end


        # TRY: 2

        # TODO: the alternative should be handled solely from/by inside the Dialog,
        # using some Intention/Capability utils, etc.
        # case Dobar.Conversation.Topic.alternative(topic, intent) do
        #   {:internal, _capability} ->
        #     {:ok, pid} = Dobar.Conversation.Dialog.start_link self
        #     Dobar.Conversation.Dialog.evaluate pid, intent
        #     {:noreply, %{topic: topic, meta: pid, parent: state.parent}}
        #   {:external, capability} ->
        #     IO.puts "external found: kill the chain and start a new dialog"
        #     {:noreply, %{topic: topic, meta: nil, parent: state.parent}}
        #   {:error, reason} ->
        #     IO.puts "fuuuuuck, no alternative found, reason: #{inspect reason}"
        #     {:noreply, %{topic: topic, meta: nil, parent: state.parent}}
        # end


        # TRY: 1

        # case IntentionProvider.alternate(intent) do
        #   {:ok, intent_def} ->
        #     intent_name = String.to_atom "#{intent.name}_conversation"
        #     IO.puts "creating meta: #{intent_name}"

        #     {:ok, pid} = Dobar.Conversation.Dialog.start_link self
        #     Dobar.Conversation.Dialog.evaluate pid, intent

        #     {:noreply, %{topic: topic, meta: pid, parent: state.parent}}

        #   {:error, reason} ->
        #     IO.puts "fuuuuuck, no alternative found, reason: #{inspect reason}"
        #     {:noreply, %{topic: topic, meta: nil, parent: state.parent}}
        # end
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
  Handles messages coming from a meta-dialog for a "cancel command".
  The receiver(parent) dialog will always stop when receiving this outcome intent.

  TODO: find if theres a way to change the `:complete` message to an `:end` message;
  this way will look more clearly what messages the Dialog is receiving.
  """
  def handle_cast({:complete, %{intent: %Intent{name: "cancel_command"} = intent}}, state) do
    if not_root?(self), do: Dobar.Conversation.Dialog.continue(state.parent)
    {:stop, :normal, %{topic: nil, meta: nil, parent: nil}}
  end

  # TBD
  # handles "switch_conversation" type of messages coming from a meta-conversation
  # def handle_cast({:complete, %{intent: %Intent{name: "switch_conversation"} = intent}}, state) do
  #   if root_conversation?(self) do
  #     Process.exit(self, :normal)
  #     {:noreply, %{topic: nil, meta: nil, parent: nil}}
  #   else
  #     # TBD
  #     send(state.parent, :switch)
  #     {:stop, :normal, nil}
  #   end
  # end

  @doc """
  Handles messages coming from a meta-dialog with a happy path; after this,
  the dialog will continue.
  Note that the meta is considered to be dead so `nil` it out!

  Note that that the `case` statement might fall into a case where
  Topic.react/1 might return a tuple of: `{:completed, topics}` that atm is not handled

  TODO: `def handle_cast({:complete, %{intent: intent, topics: topics}}, state) do`
  doesnt make any sense because you don't really use the intent there, just the topics!
  """
  def handle_cast({:complete, %{topics: topics}}, state) do
    Dobar.Conversation.Topic.fill_topics(state.topic, %Intent{entities: topics})
    case Dobar.Conversation.Topic.react(state.topic) do
      {:topic, question}   ->
        IO.puts "Topic: question #{inspect question}"
        IO.puts "________________________________________________"
      true ->
        raise "this Dialog shouldn't have been completed! see '@docs' note"
    end
    {:noreply, Map.merge(state, %{meta: nil})}
  end

  @doc """
  Handles messages coming from a meta that was canceled. In this case, the dialog
  simply tries to continue its flow by asking for the next topic capability subject.
  """
  def handle_cast(:continue, %{topic: topic} = state) do
    case Dobar.Conversation.Topic.react(topic) do
      {:topic, question}   ->
        IO.puts "Topic: question #{inspect question}"
        IO.puts "________________________________________________"
    end
    {:noreply, Map.merge(state, %{meta: nil})}
  end

  # TODO: to be defined and expressed inside the main flow concept
  def handle_info({:EXIT, from ,reason}, state) do
    IO.puts "exit: #{inspect reason}"
    {:noreply, state}
  end

  # private utils
  #

  defp alternative(intent, topic) do
    capability_name = String.to_atom intent.name
    topic_intent = Dobar.Conversation.Topic.intent(topic)
    topic_intent_name = String.to_atom topic_intent.name

    # extract the intention for the current topic
    {:ok, intention} = IntentionProvider.intention(topic_intent_name)

    # extract the capabilities of the current topic
    topic_capabilities = intention[topic_intent_name][capability_name]

    # if there's a list expressed in the `topic_capabilities`, it means the topic's
    # current intention has a reference to the input intent - the case will
    # return a {:refernce, intention}. If no list present, it searches for
    # an intention named after `capability_name` and will return an
    # {:alternative, intention}. If that doesn't find an intention, it finally
    # returns a {:noalternative, intention}
    case topic_capabilities do
      [h|t] ->
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

  # defp alternative_meta?

  defp not_root?(pid), do: root_dialog?(pid) == false

  defp root_dialog?(pid), do: pid == Process.whereis :root_dialog
end
