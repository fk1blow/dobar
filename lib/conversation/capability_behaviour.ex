defmodule Dobar.Conversation.CapabilityBehaviour do
  @moduledoc """
  this protocol defines the two functions that may be implemented by a capability,
  in order to fulfill its features - `become_starter` and `become_next`.
  """

  alias Dobar.Model.Intent

  @doc """
  signals that it can become the next dialog capability in the conversation chain.
  Responds with {:next, reply_message} if its capable of becoming
  the next capability in the conversation, or {:error, reason} if it cannot, for
  whatever reason, become the next capability.
  """
  @callback become_next(%Intent{}) :: {atom, String.t}

  @doc """
  Handles the intention by validating it, then it completes the previous intention
  in the conversation, by adding the required entities.
  It returns {:ok, new_intent} if it validates the intent(entities)
  or {:error, reason} if something is wrong with the intent
  or even the entities inside it!
  """
  @callback handle_expected(%Intent{}, %Intent{}) :: {atom, %Intent{} | String.t}
end
