defmodule Dobar.Xapp.SecondEffect do
  use Dobar.Effect

  alias Dobar.Reaction

  on %Reaction{about: :question} do
    IO.puts "should i do something to handle the ':question' reaction"
  end
end
