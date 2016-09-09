defmodule Dobar.Model.Reaction.Logging do
  defstruct about: nil,
            text: nil,
            topic_reaction: %Dobar.Model.Topic.Reaction{},
            data: nil
end
