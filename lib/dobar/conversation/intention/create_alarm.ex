defmodule Dobar.Conversation.Intention.CreateAlarm do
  use Dobar.Conversation.IntentionBehaviour

  intention :create_alarm do
    topic :time, prio: 1, entity: "datetime"
  end
end
