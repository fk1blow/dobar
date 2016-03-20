defmodule Dobar.Kapyz.Intent.AccountInfo do
  use Dobar.Kapyz.Intent, name: :account_info

  #
  # %Intent{name: "account_info", entities: []}

  def process_intent(data) do
    IO.puts "should process intent data"
  end
end
