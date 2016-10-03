# this module should be the user's own intentions definitions but for the time being,
# it can be declared here inside Dobar's Conversation app
defmodule Dobar.Xapp.Definition do
  # use Dobar.Conversation
  use Dobar.Conversation.Definition

  # intention :approve ?????

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

  intention :purge_change_fields do
    # this becomes mind blowing to comprehend...
    # topic :change_field, reference: :change_field
    topic :cancel_command, reference: :cancel_command
  end

  intention :create_alarm do
    topic :time, prio: 1, entity: [:datetime]
    topic :cancel_command, reference: :cancel_command
  end

  intention :send_message do
    topic :message_app, prio: 1, entity: [:application, :app, :app_name]
    topic :message_recipient, prio: 2, entity: [:contact, :receiver, :recipient, :dobar_contact]
    topic :message_body, prio: 3, entity: [:raw_input, :message, :message_body], prefill: false
    topic :approve, prio: 4, entity: [:confirm, :infirm]

    topic :change_field, reference: :change_field
    topic :cancel_command, reference: :cancel_command
  end

  intention :find_stuff do
    topic :subject, entity: [:pics], inert: true

    topic :change_field, reference: :change_field
    topic :cancel_command, reference: :cancel_command
  end

  intention :test_request_time do
    topic :url, entity: [:url]
    topic :times, entity: [:quantity], inert: true

    topic :cancel_command, reference: :cancel_command
  end

  intention :say_time do
    topic :where, entity: [:location], inert: true
  end

  intention :quote_of_the_day

  # IO.inspect @intentions
  # IO.puts "quote_of_the_day: #{inspect @intentions[:quote_of_the_day]}"
end
