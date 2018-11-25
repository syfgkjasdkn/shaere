*Tired of Stripe discriminating against your country?*

*Tired of PayPal not answering your support tickets?*

*Feeling adventurous? Like, **really really** adventurous?*

*Try `:shaere` today!*

---

### OMG WHAT IS SHÆRE

---

It's a bad pun, and it's also a good little library that allows your existing users "shære" [Æ](https://coinmarketcap.com/currencies/aeternity/) with each other without any additional software. No additional software for the end-user, that is, you'd still need to install and setup `:shaere`, but don't worry, it's real easy.

Just plonk `shaere` into your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    # ... deps ...
    # I usually order the deps in the order of usefullness
    # ... deps ...
    {:shaere, github: "spawnfest/shaere"}
  ]
end
```

And implement a callback module for `:shaere` to bind your user ids with private keys on the Æternity blockchain:

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
    # it works best if the operation is isolated
    # to avoid creating multiple keys for the same user
    in_some_isolated_db_transaction(fn ->
      # get a private key from a database
      if privkey = Database.privkey(user_id: user_id) do
        privkey
      else
        # if it doesn't yet exist, you can use `Shaere.Ae.keypair()`
        # to generate an approprivate privkey
        %{secret: <<privkey::64-bytes>>} = Shaere.Ae.keypair()
        # don't forget to persist this privkey (but only if it doesn't yet exist)
        :ok = Database.save_new_privkey(privkey, user_id: user_id)
        # and then also don't forget to return it
        privkey
      end
    end)
  end
  
  # ...
end
```

Don't forget to let `:shaere` know about your storage module by using `Shaere.set_storage_adapter(module)`

```elixir
# somewhere in your app startup phase
:ok = Shaere.set_storage_adapter(MyApp.ShaereStorage)

# you can change it later at runtime if you need to 
# by calling the same command but with a different module
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

To learn your address in, for example, [@shaerebot](https://t.me/shaerebot) (which is one of the example procjets, see the next section), send the bot `/address` command in a private chat.

---

#### Examples

There are two example projects (see [/examples](https://github.com/spawnfest/shaere/tree/master/examples)) which illustrate this idea, be sure to check them out! Please ...

I spent more time on them than on the actual library ...

---

#### I see a makefile

Yep. It can `make setup` and `make check`.
