use Mix.Config

config :web, Web.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [yarn: ["watch", cd: Path.expand("../assets", __DIR__)]]

config :web, Web.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/web/views/.*(ex)$},
      ~r{lib/web/templates/.*(eex)$}
    ]
  ]
