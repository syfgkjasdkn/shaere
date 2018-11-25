### shære

---

`:shaere` allows your existing users "shære" Æ with each other without any additional software (for the end-user, that is).

All you need to do is implement a callback module for `:shaere` to bind your user ids with private keys for the Æternity blockchain.

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

---

#### Getting (fake) tokens

Since this project is using Æternity's testnet, you can top the account that `:shaere` creates for you in https://faucet.aepps.com/ by pasting your address there.

To learn your address in, for example, [@shaerebot](https://t.me/shaerebot), send the bot `/address` command in a private chat.

---

#### Examples

There are two example projects (see [/examples](https://github.com/spawnfest/shaere/tree/master/examples)) which illustrate this idea, be sure to check them out! I spent more time on them than on the actual library ...
