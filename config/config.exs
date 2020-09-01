# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :banking_api,
  ecto_repos: [BankingApi.Repo]

# Configures the endpoint
config :banking_api, BankingApiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "V9H2jbhDQfw3uCy7NoW9k1z9Ve+f5+XKbMFnpRKIO28AuGglOOKb72T8XEoRjxYl",
  render_errors: [view: BankingApiWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: BankingApi.PubSub,
  live_view: [signing_salt: "QTEowj/p"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :banking_api, BankingApiWeb.Auth.Guardian,
  issuer: "banking_api",
  secret_key: "KuUT4GJrWZgsmV3YMJbZaf+dk+vGthWtAs4mnwCP7/chjtTnHlrt0UMHO8cPHLKL"

config :banking_api, BankingApi.Mailer,
  adapter: Bamboo.LocalAdapter,
  open_email_in_browser_url: "http://localhost:4000/sent_emails"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
