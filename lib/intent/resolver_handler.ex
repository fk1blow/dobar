defmodule Dobar.Intent.ResolverHandler do
  @moduledoc """
    Has the responsability to handle events and notifications related to an intent.
    An intent is an expression that was evaluated and its intention was detected.

    TODO: should be renamed to intent parser handler and break the parsing
    from the processing(coming as a result of the capability) stages in two
    distinct event handlers
      - when the response from wit.ai has arrived
      - when the capability has resolved the intention
  """
  require Logger

  use GenEvent

  @name Dobar.Intent.Resolver

  def handle_event({:evaluator_intention, intent}, state) do
    GenServer.cast @name, {:evaluate_intent, intent}
    Logger.info "intention evaluated to: #{inspect intent}"
    {:ok, state}
  end
end
