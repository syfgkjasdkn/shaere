defmodule Shaere do
  @moduledoc File.read!("README.md")
  alias Shaere.Ae

  # this is for setting a testing adapter in tests
  @ae_adapter Application.get_env(:shaere, :ae_adapter, Shaere.AeAdapter)

  @type user_id :: any

  # TODO consider using module heap or whatever it's called
  defp _storage_adapter! do
    Application.get_env(:shaere, :storage_adapter) || raise("need shaere.storage_adapter")
  end

  @doc """
  Sets the adapter module which implements `Shaere.StorageAdapterType` behaviour
  for `:shaere` to use in its `privkey/1` command.

  Example:

      Shaere.set_storage_adapter(MyApp.ShaereStorage) # => :ok

  """
  @spec set_storage_adapter(module) :: :ok
  def set_storage_adapter(storage_adapter) do
    # TODO add function exports check
    Application.put_env(:shaere, :storage_adapter, storage_adapter)
  end

  @doc """
  Fetches the balance for a user (or rather, for the privkey associated with this user) from the blockchain.

  The user id passed to this function is opaque and can be anything. The only restiriction is that the adapter that you set in `set_storage_adapter/1` needs to understand it.

  Example:

      Shaere.balance(123456) # => 100
      Shaere.balance({:id, 1234}) # => 1000
      Shaere.balance({:name, "jerry"}) # => 0

  """
  @spec balance(user_id) :: non_neg_integer
  def balance(user_id) do
    @ae_adapter.balance(user_id)
  end

  @doc """
  Fetches the privkey of a user. Just delegates to the storage adapter (see `set_storage_adapter/1`) for now.

  Example:

      Shaere.privkey("whoever") # => <<privkey::64-bytes>>

  """
  @spec privkey(user_id) :: Ae.secret()
  def privkey(user_id) do
    _storage_adapter!().privkey(user_id)
  end

  @doc """
  Computes the address for a user.

  Example:

      Shaere.address(666) # => "ak_aNdOtHeRBaSe58cHeCkEnCodEdNonSENsE"

  """
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
  @doc """
  Transfers `amount` of Æ from a user to either another user or an address.

  Example:

      sender_user_id = 1234
      receiver_user_id = 5678
      amount = 50 # 50 Æ
      Shaere.shaere(sender_user_id, receiver_user_id, amount) # => {:ok, "th_tRanSActiOn_HaSh"}

      sender_user_id = 1234
      receiver_address = "ak_aNdOtHeRBaSe58cHeCkEnCodEdNonSENsE"
      amount = 666 # 666 Æ
      Shaere.shaere(sender_user_id, receiver_address, amount) # => {:ok, "th_tRanSActiOn_HaSh"}

  """
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
