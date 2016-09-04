defmodule Dobar.Conversation.TextInputHandler do
  use GenEvent

  alias Dobar.Conversation.Intention.Evaluator

  def handle_event({:input, :text, input}, _) do
    task = Task.async(Dobar.Conversation.Intention.Evaluator,
      :evaluate_input, [{:text, input}])

    result = Task.await(task)
    IO.puts "should pass the intent to... next something-something; result...: #{inspect result}"

    {:ok, nil}
  end
end
