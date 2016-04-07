defmodule Dobar.Conversation.IntentionTest do
  use ExUnit.Case

  @moduletag :intention_case

  alias Dobar.Model.Intent
  alias Dobar.Conversation.Intention.SendMessage

  test "becomes the next dialog capability in the conversation" do
    next = SendMessage.process_next %Intent{entities: %{contact: "Dragoshy"}}
    assert next == {:next, %{entitiy: "app_name",
                             module: Dobar.Conversation.Intention.MessageApp,
                             name: :message_app}}
  end

  test "responds to the expected dialog capability" do
    {:next, expected} = SendMessage.process_next %Intent{entities: %{contact: "Dragoshy"}}
    answer = SendMessage.process_expected(expected,
      %Intent{entities: %{contact: "Dragoshy"}},
      %Intent{entities: %{app_name: "whatsapp"}})

    assert answer == {:ok,
      %Dobar.Model.Intent{confidence: 0,
                          entities: %{app_name: "whatsapp", contact: "Dragoshy"},
                          input: nil,
                          name: nil}}
  end

  test "errors when expected dialog capability receives invalid intent" do
    {:next, expected} = SendMessage.process_next %Intent{entities: %{contact: "Dragoshy"}}
    answer = SendMessage.process_expected(expected,
      %Intent{entities: %{contact: "Dragoshy"}},
      %Intent{entities: %{whatever: "whatsapp"}})

    assert answer == {:error, "cannot find the application name in the provided reply!"}
  end
end
