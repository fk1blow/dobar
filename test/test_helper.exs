ExUnit.start

Mix.Task.run "ecto.create", ~w(-r Dobar.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r Dobar.Repo --quiet)
Ecto.Adapters.SQL.begin_test_transaction(Dobar.Repo)

