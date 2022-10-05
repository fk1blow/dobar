defmodule Dobar.SagaTests do
  use ExUnit.Case, async: true

  alias Dobar.Saga

  describe "from_json/1" do
    test "returns {:error, :invalid} Saga when inputing invalid JSON" do
      assert Saga.Parser.from_json(invalid_json_fixture) == {:error, :connections}
    end

    test "returns {:ok, %Saga{}} Saga when inputing valid JSON" do
      assert Saga.Parser.from_json(valid_json_fixture) ==
               {:ok,
                %Dobar.Saga{
                  connections: [%{"from" => "root", "to" => "io"}],
                  name: nil,
                  nodes: [
                    %{
                      "component" => "Dobar.Flow.Component.RootComponent",
                      "id" => "kicker",
                      "is_root" => true
                    },
                    %{"component" => "Dobar.Flow.Component.IOComponent", "id" => "logger"}
                  ],
                  version: nil
                }}
    end
  end

  defp valid_json_fixture do
    ~s({
      "nodes": [
        {
          "component": "Dobar.Flow.Component.RootComponent",
          "is_root": true,
          "id": "kicker"
        },

        {
          "component": "Dobar.Flow.Component.IOComponent",
          "id": "logger"
        }
      ],

      "connections": [
        {
          "from": "root",
          "to": "io"
        }
      ]
    })
  end

  defp invalid_json_fixture do
    ~s({
      "nodes": [],

      "connections": []
    })
  end
end
