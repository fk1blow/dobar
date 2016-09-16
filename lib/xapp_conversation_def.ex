# this module should be the user's own intentions definitions but for the time being,
# it can be declared here inside Dobar's Conversation app
defmodule Dobar.Xapp.Definition do
  use Dobar.Conversation

  intention :cancel_command do
    relationship :meta
    topic :approve, entity: [:confirm, :infirm]
  end

  intention :change_field do
    relationship :meta
    topic :approve, entity: [:confirm, :infirm]
    topic :cancel_command, reference: :cancel_command
  end

  intention :confirmation do
    relationship :meta
    topic :approve, entity: [:confirm, :infirm]
    topic :cancel_command, reference: :cancel_command
  end

  intention :switch_conversation do
    relationship :meta
    topic :approve, entity: [:confirm, :infirm]
    topic :cancel_command, reference: :cancel_command
  end

  intention :create_alarm do
    topic :time, prio: 1, entity: "datetime"
    topic :cancel_command, reference: :cancel_command
  end

  intention :purge_change_fields do
    # this becomes mind blowing to comprehend...
    # topic :change_field, reference: :change_field
    topic :cancel_command, reference: :cancel_command
  end

  intention :send_message do
    topic :message_app, prio: 1, entity: [:application, :app, :app_name]
    topic :message_recipient, prio: 2, entity: [:contact, :receiver, :recipient]
    topic :message_body, prio: 3, entity: :input # {:input, [:message_body]}
    topic :approve, prio: 4, entity: [:confirm, :infirm]

    topic :change_field, reference: :change_field
    topic :cancel_command, reference: :cancel_command
  end

  intention :search_image do
    # topic :image_name, entity: :input
    topic :image_name, entity: {:input, [:image_name]}

    topic :cancel_command, reference: :cancel_command
  end
end
