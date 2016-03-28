defmodule Dobar.Kapyz.Capability.SearchFiles do
  use Dobar.Kapyz.Capability, name: :search_files
  alias Dobar.Models.Intent

  def react(%Intent{text: text}) do
    IO.puts "should react to the :search_files intention"
    IO.puts "text data: #{inspect text}"
  end
end
