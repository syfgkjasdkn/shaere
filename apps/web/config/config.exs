use Mix.Config

config :web,
  generators: [context_app: false]

config :web, Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "GykWHiz/VnEc0VpH8liIiKqADmUIXIHpQl78SxDpBuBQf8EgjpIgY7WFWp9Te+ED",
  render_errors: [view: Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Web.PubSub, adapter: Phoenix.PubSub.PG2]

import_config "#{Mix.env()}.exs"
