defmodule Ae do
  @moduledoc File.read!("README.md")

  def keypair do
    :enacl.sign_keypair()
  end

  def public_key(<<secret::64-bytes>>) do
    :enacl.crypto_sign_ed25519_sk_to_pk(secret)
  end

  def sign(message, <<secret::64-bytes>>) when is_binary(message) do
    :enacl.sign_detached(message, secret)
  end

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
