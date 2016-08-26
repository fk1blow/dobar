defmodule Dobar.Model.Reaction.Error do
  alias Dobar.Model
  defstruct about: nil, topic_reaction: %Model.Topic.Reaction{}, input_intent: %Model.Intent{}
end
