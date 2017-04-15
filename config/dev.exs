use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :heimchen, Heimchen.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []


# Watch static and templates for browser reloading.
config :heimchen, Heimchen.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex|haml)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

config :heimchen, :googleapikey, "AIzaSyD-tpgkm4HNAQ-YOZTwIb_ZKe_lEq3P5bU"

# Configure your database
config :heimchen, Heimchen.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "heimchen",
  password: "heimchen",
  database: "heimchen_dev",
  hostname: "127.0.0.1",
  pool_size: 10
