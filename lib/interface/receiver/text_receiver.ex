defmodule Dobar.Interface.Receiver.Text do
  @behaviour Dobar.Interface.Receiver

  def parse(input) do
    Dobar.Intent.Resolver.evaluate_input {:text, input}
  end
end
