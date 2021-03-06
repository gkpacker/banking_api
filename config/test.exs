use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.

config :banking_api, BankingApi.Repo,
  username: System.get_env("PG_USER") || "postgres",
  password: System.get_env("PG_PASSWORD") || "postgres",
  database: "banking_api_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: System.get_env("PG_HOST") || "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :banking_api, BankingApiWeb.Endpoint,
  http: [port: 4001],
  server: true

# Print only warnings and errors during test
config :logger, level: :warn

config :bcrypt_elixir, :log_rounds, 4

config :banking_api, BankingApi.Mailer, adapter: Bamboo.TestAdapter
