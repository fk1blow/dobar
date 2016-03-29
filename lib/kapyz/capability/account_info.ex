defmodule Dobar.Kapyz.Capability.AccountInfo do
  use Dobar.Kapyz.Capability, name: :account_info
  alias Dobar.Models.Intent

  def react(%Intent{name: text}) do
    IO.puts "should react to the :account_info intention"
    IO.puts "text data: #{inspect text}"
  end
end
