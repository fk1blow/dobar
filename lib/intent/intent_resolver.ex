defmodule Dobar.Intent.Resolver do
  use GenServer

  @name __MODULE__

  def start_link do
    GenServer.start_link __MODULE__, [], name: @name
  end

  def init(_) do
    {:ok, nil}
  end
end
