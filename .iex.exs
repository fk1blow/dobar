alias Dobar.Flow.Scheduler.SchedulerSupervisor
alias Dobar.Flow.Scheduler
alias Dobar.Saga.Connection
alias Dobar.Saga.Node

hello_flow = %{
  name: "hello dobar",
  connections: [
    %Connection{from: "kicker", to: "slacker"}, 
    %Connection{from: "slacker", to: "printer"},
    %Connection{from: "slacker", to: "another"}
  ],
  nodes: [
    %Node{name: "kicker", module: Dobar.Flow.Component.RootComponent, is_root: true},
    %Node{name: "slacker", module: Dobar.Flow.Component.HttpComponent},
    %Node{name: "printer", module: Dobar.Flow.Component.IOComponent},
  ]
}

start_flow = fn -> Scheduler.start_network(Flow.Scheduler, hello_flow) end

revery = fn () ->
  r Dobar.Flow.Scheduler
  r Dobar.Flow.Component
  r Dobar.Flow.Port

  start_flow.()
end

revery.()
