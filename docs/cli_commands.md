## aliasing

alias Dobar.Flow.Network

alias Dobar.Flow.Scheduler

## registry

Registry.lookup(Dobar.Flow.Scheduler.Registry, "kicker")

## starting a network

```
alias Dobar.Flow.Scheduler.SchedulerSupervisor
alias Dobar.Saga.Connection
alias Dobar.Saga.Node

Dobar.Flow.Scheduler.start_network(Flow.Scheduler, %{
  name: "hello dobar",
  connections: [%Connection{from: "kicker", to: "printer"}],
  nodes: [
    %Node{name: "kicker", module: Dobar.Flow.Component.RootComponent, is_root: true},
    %Node{name: "printer", module: Dobar.Flow.Component.IOComponent},
  ]
})
```
