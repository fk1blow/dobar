defmodule Dobar.Intent.IntentHandler do
  @moduledoc """
    TODO: should be renamed to intent parser handler and break the parsing
    from the processing(coming as a result of the capability) stages in two
    distinct event handlers
  """
  use GenEvent

  @name __MODULE__

  def register_with_manager(pid) do
    GenEvent.add_handler(:intent_mananger, @name, nil)
    :ok
  end
end
