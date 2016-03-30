defmodule Dobar.Interface.Receiver.Text do
  @behaviour Dobar.Interface.Receiver

  alias Dobar.Model.Input

  def parse(nil) do
    raise "cannot evaluate nil as an input!"
  end
  def parse(input) do
    Dobar.Intent.Resolver.evaluate_input %Input{type: :text, data: input}
  end
end
