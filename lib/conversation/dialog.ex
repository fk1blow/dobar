defmodule Dobar.Conversation.Dialog do
  use GenServer

  alias Dobar.Model.Intent
  alias Dobar.Conversation.Intention.Provider, as: IntentionProvider

  def start_link(parent) do
    GenServer.start_link __MODULE__, [parent: parent]
  end

  def start_link(name, parent) do
    GenServer.start_link __MODULE__, [parent: parent], name: name
  end

  def evaluate(pid, %Intent{} = intent) do
    GenServer.cast pid, {:evaluate, intent}
  end

  def react(pid, topic) do
    GenServer.cast pid, {:outcome, topic}
  end

  def continue(pid) do
    GenServer.cast pid, :continue
  end

  # callbacks
  #

  def init(args) do
    {:ok, %{topic: nil, meta: nil, parent: args[:parent]}}
  end

  @doc """
  Handles the intent evaluation if there is no active dialog yet; it creates
  a new dialog and starts it.
  """
  def handle_cast({:evaluate, intent}, %{topic: nil, meta: nil} = state) do
    IO.puts "begin topic"

    {:ok, topic} = Dobar.Conversation.Topic.start_link(intent)

    case Dobar.Conversation.Topic.continue(topic) do
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
    IO.puts "continue topic"

    case Dobar.Conversation.Topic.react(topic, intent) do
      {:topic, question} ->
        IO.puts "Topic: question #{inspect question}"
        IO.puts "________________________________________________"
        {:noreply, %{topic: topic, meta: nil, parent: state.parent}}

      {:completed, topic} ->
        IO.puts "The topic has been completed with: #{inspect topic}"

        if not_root?(self) do
          IO.puts "ending topic, intent: #{inspect intent.name}"
          Dobar.Conversation.Dialog.react(state.parent, topic)
        end

        {:stop, :normal, nil}

      {:nomatch, reason} ->
        IO.puts "cannot match: #{inspect reason}"

        case IntentionProvider.alternate(intent) do
          {:ok, intent_def} ->
            intent_name = String.to_atom "#{intent.name}_conversation"
            IO.puts "creating meta: #{intent_name}"

            {:ok, pid} = Dobar.Conversation.Dialog.start_link self
            Dobar.Conversation.Dialog.evaluate pid, intent

            {:noreply, %{topic: topic, meta: pid, parent: state.parent}}

          {:error, reason} ->
            IO.puts "fuuuuuck, no alternative found, reason: #{inspect reason}"
            {:noreply, %{topic: topic, meta: nil, parent: state.parent}}
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
  Handles messages coming from a meta-dialog for a "cancel command".
  The receiver(parent) dialog will always stop when receiving this outcome intent.
  """
  def handle_cast({:outcome, %{intent: %Intent{name: "cancel_command"} = intent}}, state) do
    if not_root?(self), do: Dobar.Conversation.Dialog.continue(state.parent)
    {:stop, :normal, %{topic: nil, meta: nil, parent: nil}}
  end

  # TBD
  # handles "switch_conversation" type of messages coming from a meta-conversation
  # def handle_info({:answer, %{intent: %Intent{name: "switch_conversation"}} = answer}, state) do
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

  Beware that it might fall into a case where Topic.continue/1 might return
  a tuple of: `{:completed, topics}` that atm is not handled
  """
  def handle_cast({:outcome, %{intent: intent, topics: topics}}, %{topic: topic} = state) do
    Dobar.Conversation.Topic.fill_topics topic, %Intent{entities: topics}
    case Dobar.Conversation.Topic.continue(topic) do
      {:topic, question}   ->
        IO.puts "Topic: question #{inspect question}"
        IO.puts "________________________________________________"
      true ->
        raise "this Dialog shouldn't have been completed!"
    end
    {:noreply, Map.merge(state, %{meta: nil})}
  end

  @doc """
  Handles messages coming from a meta that was canceled. In this case, the dialog
  simply tries to continue its flow by asking for the next topic capability subject.
  """
  def handle_cast(:continue, %{topic: topic} = state) do
    case Dobar.Conversation.Topic.continue(topic) do
      {:topic, question}   ->
        IO.puts "Topic: question #{inspect question}"
        IO.puts "________________________________________________"
    end
    {:noreply, Map.merge(state, %{meta: nil})}
  end

  # private utils
  #

  defp not_root?(pid), do: root_dialog?(pid) == false

  defp root_dialog?(pid), do: pid == Process.whereis :root_dialog
end
