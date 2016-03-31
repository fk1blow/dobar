defmodule Dobar.Kapyz.Capability.SearchFiles do
  use Dobar.Kapyz.Capability, name: :search_files
  alias Dobar.Model.Intent

  def react(old_intent, %Intent{name: text}) do
    IO.puts "should react to the :search_files intention"
    IO.puts "text data: #{inspect text}"
  end
end
