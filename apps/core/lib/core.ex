defmodule Core do
  @moduledoc File.read!("README.md")

  # TODO @adapter

  @spec balance(pos_integer) :: non_neg_integer
  def balance(telegram_id) do
    telegram_id
    |> privkey()
    |> Ae.fetch_account_info()
    |> case do
      %{"balance" => balance} -> balance
      nil -> 0
    end
  end

  @spec privkey(pos_integer) :: Ae.secret()
  def privkey(telegram_id) do
    Core.Storage.privkey(telegram_id)
  end

  @spec address(pos_integer) :: String.t()
  def address(telegram_id) do
    telegram_id
    |> privkey()
    |> Ae.address()
  end

  def share(from_telegram_id, "ak_" <> recipient_pubkey_base58c, amount) do
    sender_privkey = privkey(from_telegram_id)
    recipient_pubkey = Ae.decode58c(recipient_pubkey_base58c)
    spend_tx = Ae.spend_tx(sender_privkey, recipient_pubkey, amount)
    signature = Ae.sign_tx(spend_tx, sender_privkey)

    signed_tx_rlp =
      spend_tx
      |> Ae.encode_signed_tx_to_list([signature])
      |> ExRLP.encode()

    # TODO
    case Ae.send_tx(Ae.encode58c("tx", signed_tx_rlp)) do
      {:ok, %{"tx_hash" => th}} -> {:ok, th}
    end
  end

  def share(from_telegram_id, to_telegram_id, amount) do
    share(from_telegram_id, address(to_telegram_id), amount)
  end
end
