defmodule Dobar.Dialog.Capability.Feature do
  @moduledoc """
  Dialog Capability Feature

  This structure describes a capability's state and basically is a meta description
  for the capability and its flow.

  @type name the name of the feature intent
  @type value the values that match the entities - either list or nil
  @type slots represents the entities that can match from an intent
  @type matched the entity that matches the intent entities intersected with slots
  @type prio a number that indicates the priority of the capability
  @type inert if true indicates that this capability is completed, no matther the value
  @type prefill indicates that this capability may set its value during prefill/init stage
  """

  @type     name :: atom
  @type     value :: nil | [<<>>]
  @type     slots :: atom | [...]
  @type     matched :: nil | atom
  @type     prio :: number
  @type     inert :: bool
  @type     prefill :: bool

  @type t :: %__MODULE__{
            name: name,
            value: value,
            slots: slots,
            matched: matched,
            prio: prio,
            inert: inert,
            prefill: prefill
  }

  defstruct name: nil,
            value: nil,
            slots: [],
            matched: nil,
            prio: 0,
            inert: false,
            prefill: true
end
