defmodule Dobar.Reaction.Topic do
  # @type topic_reaction ::
  #   :completed |
  #   :question |
  #   :nomatch

  # defstruct type: atom | :question | :nomatch,
  #           intent: nil,
  #           features: nil

  defstruct type: :atom,
            intent: nil,
            features: nil
end
