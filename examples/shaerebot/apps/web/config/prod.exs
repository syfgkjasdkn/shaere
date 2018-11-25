use Mix.Config

# TODO
config :web, Web.Endpoint,
  url: [host: "shaere.from.network", port: 443],
  cache_static_manifest: "priv/static/cache_manifest.json",
  version: Application.spec(:web, :vsn),
  server: true,
  root: "."
