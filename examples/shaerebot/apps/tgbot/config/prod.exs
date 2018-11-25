use Mix.Config

config :tgbot,
  adapter: TGBot.NadiaAdapter

config :nadia,
  # TODO read at runtime
  token: System.get_env("SHAEREBOT_PROD_TG_TOKEN") || raise("need SHAEREBOT_PROD_TG_TOKEN")
