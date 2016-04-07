defmodule Dobar.Conversation.EndingBehaviour do
  alias Dobar.Model.Intent

  @callback handle_ending(%Intent{}) :: {atom, String.t}
end
