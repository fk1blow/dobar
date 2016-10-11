defmodule Dobar.Xapp.FirstEffect do
  use Dobar.Effect

  alias Dobar.Reaction

  on %Reaction{about: :nothing} do
    IO.puts "this shit matched"
  end

  on %Reaction{text: "xxx"} do
    IO.puts "another shit matched"
  end
end
