defmodule Dobar.Conversation.Root do
  use GenServer

  alias Dobar.Model.Intent
  alias Dobar.Conversation.Intention.Provider, as: IntentionProvider

  def start_link(name, parent \\ nil) do
    GenServer.start_link __MODULE__, [parent: parent], name: name
  end

  def init(args) do
    {:ok, %{dialog: nil, meta: nil, parent: args[:parent]}}
  end

  def evaluate_intent(pid, %Intent{} = intent) do
    GenServer.cast(pid, {:evaluate_intent, intent})
  end

  #
  # genserver Callbacks

  def handle_cast({:evaluate_intent, intent}, %{dialog: nil, meta: nil} = state) do
    IO.puts "begin dialog, intent: #{inspect intent.name}"

    {:ok, dialog} = Dobar.Conversation.Dialog.start_link(intent)

    case Dobar.Conversation.Dialog.next_topic(dialog) do
      {:topic, question}   ->
        IO.puts "Topic: question #{inspect question}"
      {:completed, topics} ->
        IO.puts "The dialog has been completed; topics: #{inspect topics}"
    end

    {:noreply, Map.merge(state, %{dialog: dialog})}
  end

  def handle_cast({:evaluate_intent, intent}, %{dialog: dialog, meta: nil, parent: parent}) do
    IO.puts "continue dialog"

    dialog = case Dobar.Conversation.Dialog.react(dialog, intent) do
      {:topic, question} ->
        IO.puts "Topic: question #{inspect question}"
        {:noreply, %{dialog: dialog, meta: nil, parent: parent}}

      {:completed, topics} ->
        IO.puts "The dialog has been completed; topics: #{inspect topics}"

        if not_root? do
          IO.puts "ending dialog, intent: #{inspect intent.name}"
          send parent, {:answer, topics}
          Process.exit(self, :normal)
        end

        # TODO: should tell the difference between meta or root
        {:noreply, %{dialog: nil, meta: nil, parent: parent}}

      {:nomatch, reason} ->
        IO.puts "cannot match: #{inspect reason}"

        case find_alternate(intent) do
          {:ok, intent_def} ->
            intent_name = String.to_atom "#{intent.name}_conversation"
            IO.puts "creating meta: #{intent_name}"

            {:ok, pid} = Dobar.Conversation.Root.start_link(intent_name, self)
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

  def handle_info({:answer, %{intent: %Intent{name: "cancel_command"}}} = answer, state) do
    IO.puts "handle_info, intent: #{inspect state.intent}"
    IO.puts ":answer: #{inspect answer}"
    {:noreply, state}
  end

  # def handle_info({:nothing, reason}, state) do
  #   IO.puts "nothing....."
  #   {:noreply, state}
  # end

  # def handle_info({:cancel, reason}, state) do
  #   IO.puts "canceling fucking...."
  #   {:stop, :normal, nil}
  # end

  # private
  #

  defp find_alternate(%Intent{confidence: confidence, name: name} = intent) do
    cond do
      confidence > 0.8 ->
        intent_name = String.to_atom(name)
        IntentionProvider.intention intent_name
      true ->
        {:error, "intent confidence to low"}
    end
  end

  defp not_root?, do: root_conversation? == false

  defp root_conversation?, do: self == Process.whereis :root_conversation
end
