### shære

---

`:shaere` allows your existing users "shære" Æ with each other without any additional software (for the end-user, that is).

Just pluck your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:shaere, github: "spawnfest/shaere"}
  ]
end
```

And implement a callback module for `:shaere` to bind your user ids with private keys for the Æternity blockchain:

```elixir
defmodule MyApp.ShaereStorage do
  @moduledoc """
  `:shaere` only needs to know how to associate your existing users' ids
  with private keys, so the only callback that it needs right now is `privkey/1`
  """
  
  @behaviour Shaere.StorageAdapterType
  
  # ...

  @impl Shaere.StorageAdapterType
  def privkey(user_id) do
    # get a private key from a database
    # if it doesn't yet exist, use `Shaere.Ae.keypair().secret`
    # to create a keypair and pick the secret part, store it in your database
    # and then return here
  end
  
  # ...
end
```

Don't forget to let `:shaere` know about your storage module by using `Shaere.set_storage_adapter(module)`

```elixir
# somewhere in your app startup phase
:ok = Shaere.set_storage_adapter(MyApp.ShaereStorage)
```

After that you can

```elixir
# get the address of a user on the blockchain
Shaere.address(user_id) # => "ak_uBXfaCX5uYVMaePtS2ybXv4nahu8ALfmGcsgge9ghrfAHD6Wf"

# get the balance of a user on the blockchain
Shaere.balance(user_id) # => 5000

# send tokens from one user to another
Shaere.shaere(sender_user_id, receiver_user_id, amount) # => {:ok, "th_2A9PibNnDbNDNJ78ZQxMdfXAPP8dZ1XnhiZpJBJSy4aefixtDr"}
```

---

#### Getting (fake) tokens

Since this project is using Æternity's testnet, you can top the account that `:shaere` creates for you in https://faucet.aepps.com/ by pasting your address there.

To learn your address in, for example, [@shaerebot](https://t.me/shaerebot), send the bot `/address` command in a private chat.

---

#### Examples

There are two example projects (see [/examples](https://github.com/spawnfest/shaere/tree/master/examples)) which illustrate this idea, be sure to check them out! I spent more time on them than on the actual library ...
