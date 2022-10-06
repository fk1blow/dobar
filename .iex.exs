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
      "is_root": true
    },

    {
      "component": "Dobar.Flow.Component.IOComponent",
      "id": "logger"
    }
  ],

  "connections": [
    {
      "from": "root",
      "to": "logger"
    }
  ]
})

Flow.from_json(saga_json)
