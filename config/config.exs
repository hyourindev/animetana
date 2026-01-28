# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :yunaos,
  ecto_repos: [Yunaos.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :yunaos, YunaosWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: YunaosWeb.ErrorHTML, json: YunaosWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Yunaos.PubSub,
  live_view: [signing_salt: "WYh6vVa+"]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :yunaos, Yunaos.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  yunaos: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.12",
  yunaos: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# JWT secret for token signing (override in prod via JWT_SECRET env var)
config :yunaos, :jwt_secret, "dev-only-jwt-secret-do-not-use-in-production"

# Configure ExAws for S3-compatible storage (MinIO)
config :ex_aws,
  json_codec: Jason

config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 9000,
  region: "us-east-1"

config :yunaos, :s3,
  bucket: "yunaos"

# Configure Ueberauth for OAuth
config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "email profile"]}
  ]

# Google OAuth credentials (override in dev.exs and runtime.exs)
config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: "REPLACE_ME",
  client_secret: "REPLACE_ME"

# AI Enrichment — Vercel AI Gateway
config :yunaos, :enrichment,
  gateway_url: "https://api.vercel.ai/v1/chat/completions",
  model: "google/gemini-3-flash",
  batch_size: 15,
  request_delay_ms: 500,
  max_retries: 3

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
