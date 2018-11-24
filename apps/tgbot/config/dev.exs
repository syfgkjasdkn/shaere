use Mix.Config

config :tgbot,
  adapter: TGBot.NadiaAdapter

config :nadia,
  token: System.get_env("SHAEREBOT_DEV_TG_TOKEN") || raise("need SHAEREBOT_DEV_TG_TOKEN")
