defmodule Dobar.Interface.Receiver.Text do
  @behaviour Dobar.Interface.Receiver

  alias Dobar.Model.Input.Text

  def parse(nil) do
    raise "cannot evaluate nil as an input!"
  end
  def parse(input) do
    GenEvent.notify :intent_events, {:text_input_evaluated, %Text{type: :text, data: input}}
  end
end
