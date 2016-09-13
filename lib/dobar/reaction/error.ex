defmodule Dobar.Reaction.Error do
  defstruct about: nil,
            topic_reaction: %Dobar.Reaction.Topic{},
            text: nil,
            input_intent: %Dobar.Model.Intent{}
end
