defmodule Dobar.Intent.State do
  @moduledoc """
  It holds the "state" of the capability-intention resolver
  """

  @agent_name Dobar.Intent.State

  def start_link do
    Agent.start_link(fn -> Map.new end, name: @agent_name)
  end
end
