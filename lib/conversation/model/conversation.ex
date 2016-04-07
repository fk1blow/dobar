defmodule Dobar.Conversation.Model.Conversation do
  defstruct expected: %{capability: nil, intention: nil}, intent: %Dobar.Model.Intent{}
end
