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

  @doc """
  Handles a cast for intent evaluation wich matches only if the receiving pid
  has no meta a not dialog.
  When this function is called, it asumes it should create a new dialog and start it!
  """
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

  @doc """
  Handles a cast for intent evaluation wich matches only if the receiving pid
  doesn't have a meta-conversation, which means it will continue the dialog.
  If the receiving process is not the root, it stops itself and sends a message
  answer to the parent, passing the dialog completed
  """
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
          {:noreply, %{dialog: nil, meta: nil, parent: parent}}
        end

        {:stop, :normal, nil}

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

  @doc """
  Handles a cast for intent evaluation which matches only if the receiving pid
  has a meta, calling `evaluate_intent` on that pid.
  """
  def handle_cast({:evaluate_intent, intent}, %{meta: meta} = state) do
    IO.puts "continue dialog, with meta"
    Dobar.Conversation.Root.evaluate_intent meta, intent
    {:noreply, state}
  end

  @doc """
  Handles "cancel_command" coming from the implicit "cancel" meta-conversation
  capability intention-thingy. If the receiver is a meta conversation, it stops and
  sends a message to its parent to notify that it should continue with its
  conversation happy-path
  """
  def handle_info({:answer, %{intent: %Intent{name: "cancel_command"} = intent}}, state) do
    if root_conversation?(self) do
      Process.exit(self, :normal)
      {:noreply, %{dialog: nil, meta: nil, parent: nil}}
    else
      send(state.parent, :continue)
      {:stop, :normal, nil}
    end
  end

  # handles "switch_conversation" type of messages coming from a meta-conversation
  # def handle_info({:answer, %{intent: %Intent{name: "switch_conversation"}} = answer}, state) do
  #   if root_conversation?(self) do
  #     Process.exit(self, :normal)
  #     {:noreply, %{dialog: nil, meta: nil, parent: nil}}
  #   else
  #     # TBD
  #     send(state.parent, :switch)
  #     {:stop, :normal, nil}
  #   end
  # end

  # handles a response coming from a happy-path meta-conversation
  def handle_info({:answer, %{intent: intent, topics: topics}}, %{dialog: dialog} = state) do
    Dobar.Conversation.Dialog.fill_topics dialog, %Intent{entities: topics}

    case Dobar.Conversation.Dialog.next_topic(dialog) do
      {:topic, question}   ->
        IO.puts "Topic: question #{inspect question}"
        IO.puts "________________________________________________"
      # TBD: cannot create a meta-conversation if every slot has been filled
      # TODO: after implementing `change_multiple_slots` intent, find if there's a need
      # for this kinds of matcher
      # {:completed, topics} ->
      #   IO.puts "The dialog has been completed; topics: #{inspect topics}"
    end

    {:noreply, Map.merge(state, %{meta: nil})}
  end

  # handles a response coming from a canceled meta-conversation
  def handle_info(:continue, %{dialog: dialog} = state) do
    case Dobar.Conversation.Dialog.next_topic(dialog) do
      {:topic, question}   ->
        IO.puts "Topic: question #{inspect question}"
        IO.puts "________________________________________________"
    end

    {:noreply, Map.merge(state, %{meta: nil})}
  end

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
