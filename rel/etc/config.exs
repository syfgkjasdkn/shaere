use Mix.Config

env! = fn var, type ->
  val = System.get_env(var) || raise("need #{var} set")

  try do
    case type do
      :string -> val
      :integer -> String.to_integer(val)
    end
  rescue
    _error ->
      raise(ArgumentError, "couldn't parse #{val} as #{type}")
  end
end

config :web, Web.Endpoint,
  http: [:inet6, port: env!.("WEB_PORT", :integer)],
  secret_key_base: env!.("WEB_SECRET_KEY_BASE", :string)
