defmodule Dobar.Xapp.Conversation.Definition do
  use Dobar.Conversation

  # this should actually be internal to the Dialog Species modules
  intention :carrier_bearer do
    relationship :meta
  end

  intention :cancel_command do
    relationship :meta
    topic :approve, entity: [:confirm, :infirm]
  end

  intention :change_field do
    relationship :meta
    topic :approve, entity: [:confirm, :infirm]
    topic :cancel_command, reference: :cancel_command
  end

  intention :change_recipient do
    relationship :meta
    topic :message_recipient, prio: 2, entity: "contact"
    topic :cancel_command, reference: :cancel_command
  end

  intention :confirmation do
    relationship :meta
    topic :approve, entity: [:confirm, :infirm]
    topic :cancel_command, reference: :cancel_command
  end

  intention :create_alarm do
    topic :time, prio: 1, entity: "datetime"
    topic :cancel_command, reference: :cancel_command
  end

  intention :purge_change_fields do
    # this becomes mind blowing to understand...
    # topic :change_field, reference: :change_field
    topic :cancel_command, reference: :cancel_command
  end

  intention :switch_conversation do
    relationship :meta
    topic :approve, entity: [:confirm, :infirm]
    topic :cancel_command, reference: :cancel_command
  end

  intention :send_message do
    topic :message_app, prio: 1, entity: [:application, :app, :app_name]
    topic :message_recipient, prio: 2, entity: [:contact, :receiver, :recipient]
    topic :message_body, prio: 3, entity: :input
    topic :approve, prio: 4, entity: [:confirm, :infirm]

    topic :change_field, reference: :change_field
    topic :cancel_command, reference: :cancel_command
  end
end
