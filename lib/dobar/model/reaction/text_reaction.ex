defmodule Dobar.Model.Reaction.Text do
  defstruct about: nil,
            # this field mostly describes stuff that happened outside Topic's
            # reactions eg: "completed dialog", etc
            text: nil,
            topic_reaction: %Dobar.Model.Topic.Reaction{}
end
