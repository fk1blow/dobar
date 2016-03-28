defmodule Dobar.Intent.IntentHandler do
  @moduledoc """
    Has the responsability to handle events and notifications related to an intent.
    An intent is an expression that was evaluated and its intention was detected.

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
