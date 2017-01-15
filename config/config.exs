# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :heimchen,
  ecto_repos: [Heimchen.Repo]

# Configures the endpoint
config :heimchen, Heimchen.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "SZ1Gi1Z2yKJW6JJI3/iZBuwDUkgmZzTUNOx5kPdjL7AjK7bMrZk95OBn5lFkpGUz",
  render_errors: [view: Heimchen.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Heimchen.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :template_engines,
  haml: PhoenixHaml.Engine

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
