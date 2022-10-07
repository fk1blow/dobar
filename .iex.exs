# alias Dobar.Flow.Scheduler.SchedulerSupervisor
# alias Dobar.Flow.Scheduler
# alias Dobar.Saga.Connection
# alias Dobar.Saga.Node

# hello_flow = %{
#   name: "hello dobar",
#   connections: [
#     %Connection{from: "kicker", to: "slacker"},
#     %Connection{from: "slacker", to: "printer"},
#     %Connection{from: "slacker", to: "another"}
#   ],
#   nodes: [
#     %Node{id: "kicker", module: Dobar.Flow.Component.RootComponent, is_root: true},
#     %Node{id: "slacker", module: Dobar.Flow.Component.HttpComponent},
#     %Node{id: "printer", module: Dobar.Flow.Component.IOComponent},
#   ]
# }

# start_flow = fn -> Scheduler.start_network(Flow.Scheduler, hello_flow) end

# revery = fn () ->
#   r Dobar.Flow.Scheduler
#   r Dobar.Flow.Component
#   r Dobar.Flow.Port

#   start_flow.()
# end

# revery.()

alias Dobar.Flow

saga_json = ~s({
  "name": "hello world",

  "nodes": [
    {
      "id": "kicker",
      "component": "Dobar.Flow.Component.RootComponent",
      "is_root": true,
      "ports": {
        "output": 1
      }
    },

    {
      "id": "la_intervale",
      "component": "Dobar.Flow.Component.PeriodicalComponent",
      "ports": {
        "input": 1,
        "output": 2,
        "ended": 5
      }
    },

    {
      "component": "Dobar.Flow.Component.HttpComponent",
      "id": "http_call",
      "ports": {
        "input": 2,
        "result": 3,
        "error": 4
      }
    },

    {
      "component": "Dobar.Flow.Component.IOComponent",
      "id": "network_ended_logger",
      "ports": {
        "input": 5
      }
    },

    {
      "component": "Dobar.Flow.Component.IOComponent",
      "id": "result_logger",
      "ports": {
        "input": 3
      }
    },

    {
      "component": "Dobar.Flow.Component.IOComponent",
      "id": "error_logger",
      "ports": {
        "input": 4
      }
    }
  ],

  "connections": [
    {
      "id": 1,
      "from": "kicker",
      "to": "la_intervale"
    },

    {
      "id": 2,
      "from": "la_intervale",
      "to": "http_call"
    },

    {
      "id": 3,
      "from": "http_call",
      "to": "result_logger"
    },

    {
      "id": 4,
      "from": "http_call",
      "to": "error_logger"
    },

    {
      "id": 5,
      "from": "la_intervale",
      "to": "network_ended_logger"
    }
  ]
})

Flow.from_json(saga_json)

# :observer.start
