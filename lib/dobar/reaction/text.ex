defmodule Dobar.Reaction.Text do
  defstruct about: nil,
            # this field mostly describes stuff that happened outside Topic's
            # reactions eg: "completed dialog", etc
            text: nil,
            # topic_reaction: %Dobar.Reaction.Text{}
            topic_reaction: nil
end
