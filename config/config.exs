# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# # Configures the endpoint
# config :dobar, Dobar.Endpoint,
#   url: [host: "localhost"],
#   root: Path.dirname(__DIR__),
#   secret_key_base: "r8j41QSJNrq2ZqivWM/AoAAJg6VGeVIA9MBFx4VLKV8fPR/jnlz85CMdSnRLBvp0",
#   render_errors: [accepts: ~w(html json)],
#   pubsub: [name: Dobar.PubSub,
#            adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configures Dobar's conversation interface
config :dobar, Dobar.Conversation,
  adapter: Dobar.Interface.Adapter.Console,
  definition: Dobar.Xapp.Definition,
  responders: [
    {Dobar.Xapp.GenericResponder, []},
    {Dobar.Xapp.AnotherGenericResponder, []}
  ],
  evaluator: [service: Dobar.Conversation.Intention.Evaluator.Wit,
              token: "YH3PPLSK2L3QRTFMWNAY5NTGUJGWOKJ6"]

config :dobar, Robot.Waka,
  adapter: Dobar.Interface.Adapter.Console,
  conversation: Dobar.Xapp.Definition,
  responders: [
    {Dobar.Xapp.GenericResponder, []},
    {Dobar.Xapp.AnotherGenericResponder, []}
  ],
  # the service module should be shorter and not necessary included inside the intention
  evaluator: [service: Dobar.Conversation.Intention.Evaluator.Wit,
              token: "YH3PPLSK2L3QRTFMWNAY5NTGUJGWOKJ6"]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# import_config "#{Mix.env}.exs"
