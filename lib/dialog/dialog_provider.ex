# currently not used; TBD
defmodule Dobar.Dialog.Provider do
  use GenServer

  alias Dobar.Model.Intent

  alias Dobar.Dialog.Species.Router

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_) do
    {:ok, nil}
  end

  def dialog(%Intent{name: name}) do
    raise "not imeplemented"
  end

  defp dialog_routes do
    IO.puts routes
  end
end
