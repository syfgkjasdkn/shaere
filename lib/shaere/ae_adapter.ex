defmodule Shaere.AeAdapter do
  @moduledoc false
  @behaviour Shaere.AeAdapterType
  alias Shaere.Ae

  @impl true
  def balance(telegram_id) do
    telegram_id
    |> Shaere.privkey()
    |> Ae.fetch_account_info()
    |> case do
      %{"balance" => balance} -> balance
      nil -> 0
    end
  end

  @impl true
  def shaere(<<sender_privkey::64-bytes>>, "ak_" <> recipient_pubkey_base58c, amount) do
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
end
