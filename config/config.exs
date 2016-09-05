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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# import_config "#{Mix.env}.exs"

# Configure dobar intent evaluators
config :dobar, Intention.Evaluator,
  service: Dobar.Conversation.Intention.Evaluator.Wit,
  opts: [token: "YH3PPLSK2L3QRTFMWNAY5NTGUJGWOKJ6"]

# Configures Dobar's conversation interface
config :dobar, Dialog.Interface,
  adapter: Dobar.Interface.Adapter.Console,
  responders: nil

# Configure the intentions definitions
# These configs should be defined inside the host app, not inside Dobar itsel!!!
config :dobar, Intentions.Definitions,
  intentions: Dobar.Intentions
