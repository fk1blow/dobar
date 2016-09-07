defmodule Dobar.Model.Reaction.Text do
  defstruct about: nil,
            text: nil, # cannot tell the meaning of this field
            topic_reaction: %Dobar.Model.Topic.Reaction{}
end
