defmodule Shaere.StorageAdapterType do
  @moduledoc """
  TODO

  Need to implement a single callback, `privkey/1` which accepts an opaque user id
  and returns a privkey, you can use `Shaere.Ae.keypair().secret` to generate a privkey for a new user.
  """

  @callback privkey(user_id :: any) :: Shaere.Ae.secret()
end
