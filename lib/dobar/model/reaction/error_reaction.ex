defmodule Dobar.Model.Reaction.Error do
  defstruct about: nil,
            topic_reaction: %Dobar.Model.Topic.Reaction{},
            input_intent: %Dobar.Model.Intent{}
end
