defmodule Dobar.Conversation.Root do
  use GenServer

  alias Dobar.Model.Intent
  alias Dobar.Conversation.Intention.Provider, as: IntentionProvider

  def start_link(parent) do
    GenServer.start_link __MODULE__, [parent: parent]
  end

  def start_link(name, parent) do
    GenServer.start_link __MODULE__, [parent: parent], name: name
  end

  def init(args) do
    {:ok, %{dialog: nil, meta: nil, parent: args[:parent]}}
  end

  def evaluate_intent(pid, %Intent{} = intent) do
    IO.puts "intent: #{inspect intent}"
    GenServer.cast(pid, {:evaluate_intent, intent})
  end

  #
  # genserver Callbacks

  def handle_cast({:evaluate_intent, intent}, %{dialog: nil, meta: nil} = state) do
    IO.puts "begin dialog"

    {:ok, dialog} = Dobar.Conversation.Dialog.start_link(intent)

    case Dobar.Conversation.Dialog.next_topic(dialog) do
      {:topic, question}   ->
        IO.puts "Topic: question #{inspect question}"
        IO.puts "________________________________________________"
      {:completed, topics} ->
        IO.puts "The dialog has been completed; topics: #{inspect topics}"
    end

    {:noreply, Map.merge(state, %{dialog: dialog})}
  end

  def handle_cast({:evaluate_intent, intent}, %{dialog: dialog, meta: nil, parent: parent}) do
    IO.puts "continue dialog"

    case Dobar.Conversation.Dialog.react(dialog, intent) do
      {:topic, question} ->
        IO.puts "Topic: question #{inspect question}"
        IO.puts "________________________________________________"
        {:noreply, %{dialog: dialog, meta: nil, parent: parent}}

      {:completed, dialog} ->
        IO.puts "The dialog has been completed with: #{inspect dialog}"

        if not_root?(self) do
          IO.puts "ending dialog, intent: #{inspect intent.name}"
          send parent, {:answer, dialog}
          Process.exit(self, :normal)
        end

        # TODO: should tell the difference between meta or root
        # TODO: ambigous logic here?!?!?!
        {:noreply, %{dialog: nil, meta: nil, parent: parent}}

      {:nomatch, reason} ->
        IO.puts "cannot match: #{inspect reason}"

        case find_alternate(intent) do
          {:ok, intent_def} ->
            intent_name = String.to_atom "#{intent.name}_conversation"
            IO.puts "creating meta: #{intent_name}"

            {:ok, pid} = Dobar.Conversation.Root.start_link self
            Dobar.Conversation.Root.evaluate_intent pid, intent

            {:noreply, %{dialog: dialog, meta: pid, parent: parent}}

          {:error, reason} ->
            IO.puts "fuuuuuck, no alternative found, reason: #{inspect reason}"
            {:noreply, %{dialog: dialog, meta: nil, parent: parent}}
        end
    end
  end

  def handle_cast({:evaluate_intent, intent}, %{meta: meta} = state) do
    IO.puts "continue dialog, with meta"
    Dobar.Conversation.Root.evaluate_intent meta, intent
    {:noreply, state}
  end

  # handles "cancel_command" type of messages coming from a meta-conversation
  def handle_info({:answer, %{intent: %Intent{name: "cancel_command"} = intent}}, state) do
    IO.puts "handle_info cancel_command"
    IO.puts "answer intent: #{inspect intent}"

    # TBD!!!
    send state.parent, {:canceled, %{intent: intent}}

    {:stop, :normal, %{dialog: nil, meta: nil, parent: nil}}
  end

  # handles "switch_conversation" type of messages coming from a meta-conversation
  # def handle_info({:answer, %{intent: %Intent{name: "switch_conversation"}} = answer}, state) do
  #   IO.puts "handle_info cancel_command"
  #   IO.puts ":answer: #{inspect answer}"
  #   send state.parent, {:nothing, "asdkhad"}
  #   # {:stop, :normal, %{dialog: nil, meta: nil, parent: nil}}
  #   {:noreply, state}
  # end

  # handles a completed response coming from a canceled meta-conversation
  def handle_info({:canceled, intent}, %{dialog: dialog} = state) do
    IO.puts "meta intent canceled; continue with conversation"

    case Dobar.Conversation.Dialog.next_topic(dialog) do
      {:topic, question}   ->
        IO.puts "Topic: question #{inspect question}"
        IO.puts "________________________________________________"
      {:completed, topics} ->
        IO.puts "The dialog has been completed; topics: #{inspect topics}"
    end

    {:noreply, Map.merge(state, %{meta: nil})}
  end

  # handles a completed response type of messages coming from a meta-conversation
  def handle_info({:answer, %{intent: intent, topics: topics}}, %{dialog: dialog} = state) do
    IO.puts "handle_info normal_command"
    Dobar.Conversation.Dialog.fill_topics dialog, %Intent{entities: topics}
    {:noreply, state}
  end

  # woooot?????
  # def handle_info({:nothing, nothing}, state) do
  #   IO.puts "handle_info :nothing"
  #   {:noreply, Map.merge(state, %{meta: nil})}
  # end

  # private utils
  #

  defp find_alternate(%Intent{confidence: confidence, name: intent_name} = intent) do
    cond do
      confidence > 0.8 -> IntentionProvider.intention String.to_atom(intent_name)
      true             -> {:error, "intent confidence to low"}
    end
  end

  defp not_root?(pid), do: root_conversation?(pid) == false

  defp root_conversation?(pid), do: pid == Process.whereis :root_conversation
end
