defmodule Dobar.Xapp.FirstEffect do
  use Dobar.Effect

  alias Dobar.Reaction

  # def handle_on(%Reaction{about: :question}) do
  #   IO.puts "this shit matched"
  #   :blablabla
  # end

  on %Reaction{about: :question} = reaction do
    IO.puts "can i haz reaction: #{inspect reaction}"
    # IO.puts "this shit matched"
  end

  # on %Reaction{text: "xxx"} do
  #   IO.puts "another shit matched"
  # end
end
