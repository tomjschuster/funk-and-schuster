# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :funk_and_schuster,
  ecto_repos: [FunkAndSchuster.Repo]

# Configures the endpoint
config :funk_and_schuster, FunkAndSchusterWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "B6gIMt263Iw/qrIrCCNzcoHi4cOpYSU2wyM5gdFjmlOOB2Ira6z/3Sb3ug8pj5QO",
  render_errors: [view: FunkAndSchusterWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: FunkAndSchuster.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
