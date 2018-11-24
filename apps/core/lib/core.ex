defmodule Core do
  @moduledoc File.read!("README.md")

  @adapter Application.get_env(:core, :adapter) || raise("need core.adapter")

  @spec balance(pos_integer) :: non_neg_integer
  def balance(telegram_id) do
    @adapter.balance(telegram_id)
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

  # TODO spec
  defp _shaere(<<sender_privkey::64-bytes>>, "ak_" <> _rest = recipient_address, amount) do
    @adapter.shaere(sender_privkey, recipient_address, amount)
  end

  # TODO
  def shaere(from_telegram_id, "ak_" <> _rest = recipient_address, amount) do
    from_telegram_id
    |> Core.privkey()
    |> _shaere(recipient_address, amount)
  end

  def shaere(from_telegram_id, to_telegram_id, amount) do
    from_telegram_id
    |> Core.privkey()
    |> _shaere(Core.address(to_telegram_id), amount)
  end
end
