defmodule Core.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      Core.Storage
    ]

    :ok = Shaere.set_storage_adapter(Core.Storage)

    opts = [strategy: :one_for_one, name: Core.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
