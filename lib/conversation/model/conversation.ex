defmodule Dobar.Conversation.Model.Conversation do
  defstruct expected: %{topic: nil, intention: nil}, intent: %Dobar.Model.Intent{}
end
