defmodule Dobar.Intent.Evaluator do
  @moduledoc """
    It extracts the intent from an input(text, for now) and outputs an
    %Intent struct the intent representation

    To evaluate the input, it needs a service that knows how to evaluate
    such types of input, services like wit.ai - default, for now

    TODO: see if making this module a genserver would make it more reliable
    and concise - self healing(through supervision), better api clarity, etc
  """

  def evaluate_intention({:text, input}) do
    IO.puts "should evaluate the intention of the input"
  end
end
