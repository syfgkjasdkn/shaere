defmodule Ae do
  @moduledoc File.read!("README.md")

  @type public_key :: <<_::256>>
  @type secret :: <<_::512>>

  @doc """
  Generates a private/public key pair.

  Example:
      
      iex> %{public: <<pubkey::32-bytes>>, secret: <<_privkey::64-bytes>>} = keypair()
      iex> byte_size(pubkey) # wtf
      32

  """
  @spec keypair :: %{public: public_key, secret: secret}
  def keypair do
    :enacl.sign_keypair()
  end

  @doc """
  Computes a public key from a private key.

  Example:
      
      iex> %{public: <<pubkey::32-bytes>>, secret: <<privkey::64-bytes>>} = keypair()
      iex> pubkey == public_key(privkey)
      true

  """
  @spec public_key(secret) :: public_key
  def public_key(<<secret::64-bytes>>) do
    :enacl.crypto_sign_ed25519_sk_to_pk(secret)
  end

  @spec sign(message :: binary, secret) :: signature :: binary
  def sign(message, <<secret::64-bytes>>) when is_binary(message) do
    :enacl.sign_detached(message, secret)
  end

  @doc """
  Represents a public or a private key as an aeternity account address.

  Example:

      iex> %{secret: <<privkey::64-bytes>>} = keypair()
      iex> match?("ak_" <> _rest, address(privkey))
      true

      iex> %{public: <<pubkey::32-bytes>>} = keypair()
      iex> match?("ak_" <> _rest, address(pubkey))
      true

  """
  @spec address(public_key | secret) :: String.t()
  def address(<<pubkey::32-bytes>>) do
    encode58c("ak", pubkey)
  end

  def address(<<secret::64-bytes>>) do
    secret
    |> public_key()
    |> address()
  end

  @spec encode58c(binary, binary) :: binary
  def encode58c(prefix, payload) when is_binary(prefix) do
    prefix <> "_" <> encode58c(payload)
  end

  @spec encode58c(binary) :: binary
  def encode58c(payload) when is_binary(payload) do
    (payload <> checksum(payload))
    |> :base58.binary_to_base58()
    |> to_string()
  end

  @spec checksum(binary) :: binary
  defp checksum(payload) do
    <<checksum::4-bytes, _::bytes>> = :crypto.hash(:sha256, :crypto.hash(:sha256, payload))
    checksum
  end
end
