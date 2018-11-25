defmodule Shaere do
  @moduledoc File.read!("README.md")
  alias Shaere.Ae

  # this is for setting a testing adapter in tests
  @ae_adapter Application.get_env(:shaere, :ae_adapter) || raise("need shaere.ae_adapter")

  @type user_id :: any

  # TODO consider using module heap or whatever it's called
  defp _storage_adapter! do
    Application.get_env(:shaere, :storage_adapter) || raise("need shaere.storage_adapter")
  end

  @spec set_storage_adapter(module) :: :ok
  def set_storage_adapter(storage_adapter) do
    # TODO add function exports check
    Application.put_env(:shaere, :storage_adapter, storage_adapter)
  end

  @spec balance(user_id) :: non_neg_integer
  def balance(user_id) do
    @ae_adapter.balance(user_id)
  end

  @spec privkey(user_id) :: Ae.secret()
  def privkey(user_id) do
    _storage_adapter!().privkey(user_id)
  end

  @spec address(user_id) :: String.t()
  def address(telegram_id) do
    telegram_id
    |> privkey()
    |> Ae.address()
  end

  @spec _shaere(Ae.secret(), String.t(), pos_integer) :: {:ok, th :: String.t()} | {:error, any}
  defp _shaere(<<sender_privkey::64-bytes>>, "ak_" <> _rest = recipient_address, amount) do
    @ae_adapter.shaere(sender_privkey, recipient_address, amount)
  end

  # TODO
  def shaere(sender_user_id, "ak_" <> _rest = recipient_address, amount) do
    sender_user_id
    |> privkey()
    |> _shaere(recipient_address, amount)
  end

  def shaere(sender_user_id, receiver_user_id, amount) do
    sender_user_id
    |> privkey()
    |> _shaere(address(receiver_user_id), amount)
  end
end
