defmodule Dobar do
  defmodule Intent do
    @type t :: %__MODULE__{
      name: binary,
      input: binary,
      entities: map,
      confidence: float
    }

    defstruct name: nil,
              input: nil,
              entities: %{},
              confidence: 0.0
  end

  defmodule Reaction do
    alias Dobar.Intent

    @type t :: %__MODULE__{
      about: atom,
      text: binary,
      features: map,
      trigger: Intent.t,
      other: any
    }

    defstruct about: nil,
              text: nil,
              features: %{},
              trigger: %Intent{},
              other: nil
  end

  defmodule EvaluationError do
    @type t :: %__MODULE__{
      reason: binary,
      other: any
    }

    defstruct reason: nil,
              other: nil
  end
end
