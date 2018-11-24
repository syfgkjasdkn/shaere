defmodule Ae do
  @moduledoc File.read!("README.md")

  @type public_key :: <<_::256>>
  @type secret :: <<_::512>>

  @default_tx_ttl 500
  @default_tx_fee 1
  @version 1
  @tag_size 8
  @hash_bytes_size 32

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

  @spec hash(binary) :: binary
  def hash(data) do
    {:ok, hash} = :enacl.generichash(@hash_bytes_size, data)
    hash
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

  @spec decode58c(binary) :: binary
  def decode58c(payload) do
    decoded_payload =
      payload
      |> String.to_charlist()
      |> :base58.base58_to_binary()

    bsize = byte_size(decoded_payload) - 4
    <<data::size(bsize)-bytes, _checksum::4-bytes>> = decoded_payload
    data
  end

  @spec checksum(binary) :: binary
  defp checksum(payload) do
    <<checksum::4-bytes, _::bytes>> = :crypto.hash(:sha256, :crypto.hash(:sha256, payload))
    checksum
  end

  @spec spend_tx(secret, public_key, integer, Keyword.t()) :: map
  def spend_tx(<<sender_privkey::64-bytes>>, <<receiver_pubkey::32-bytes>>, amount, opts) do
    fee = opts[:fee] || @default_tx_fee
    payload = opts[:payload] || ""
    ttl = opts[:ttl] || @default_tx_ttl
    nonce = opts[:nonce] || _next_nonce(sender_privkey)

    # TODO struct
    %{
      receiver: receiver_pubkey,
      amount: amount,
      payload: payload,
      version: @version,
      senders: [public_key(sender_privkey)],
      nonce: nonce,
      fee: fee,
      ttl: ttl
    }
  end

  # TODO struct
  @spec sign_tx(map, secret) :: binary
  def sign_tx(spend_tx, privkey) do
    rlp =
      spend_tx
      |> encode_spend_tx_to_list()
      |> ExRLP.encode()

    sign("ae_mainnet" <> rlp, privkey)
  end

  def hash_tx(spend_tx, signatures) do
    spend_tx
    |> encode_signed_tx_to_list(signatures)
    |> ExRLP.encode()
    |> hash()
  end

  def encode_signed_tx_to_list(spend_tx, signatures) do
    [
      :binary.encode_unsigned(object_type_to_tag(:signed_tx)),
      :binary.encode_unsigned(@version),
      signatures,
      spend_tx |> encode_spend_tx_to_list() |> ExRLP.encode()
    ]
  end

  def encode_spend_tx_to_list(%{
        receiver: receiver,
        amount: amount,
        payload: payload,
        senders: [sender],
        fee: fee,
        ttl: ttl,
        nonce: nonce
      }) do
    [
      :binary.encode_unsigned(object_type_to_tag(:spend_tx)),
      :binary.encode_unsigned(@version),
      <<id_type_to_tag(:account)::size(@tag_size)-unsigned-integer, sender::bytes>>,
      <<id_type_to_tag(:account)::size(@tag_size)-unsigned-integer, receiver::bytes>>,
      :binary.encode_unsigned(amount),
      :binary.encode_unsigned(fee),
      :binary.encode_unsigned(ttl),
      :binary.encode_unsigned(nonce),
      payload
    ]
  end

  @spec _next_nonce(public_key | secret | String.t()) :: pos_integer
  defp _next_nonce(account_id_or_key) do
    case fetch_account_info(account_id_or_key) do
      %{"nonce" => nonce} -> nonce + 1
      nil -> 1
    end
  end

  @doc """
  Fetches the account info. Returns something not quite unlike

      %{
        "balance" => 250,
        "id" => "ak_2okXACqGyq8JMLYgj3okriUVHktecxfzzdzX7cuma4wMFUXntU",
        "nonce" => 0
      }

  See http://aeternity.com/epoch-api-docs/?config=https://raw.githubusercontent.com/aeternity/epoch/master/apps/aehttp/priv/swagger.json#/external/GetAccountByPubkey
  """
  @spec fetch_account_info(public_key | secret | String.t()) :: map | nil
  def fetch_account_info("ak_" <> _account = account) do
    case :httpc.request('https://sdk-edgenet.aepps.com/v2/accounts/#{account}') do
      {:ok, {{_version, 200, _description}, _resp_headers, resp_body}} ->
        Jason.decode!(resp_body)

      {:ok, {{_version, 404, _description}, _resp_headers, _resp_body}} ->
        nil
    end
  end

  def fetch_account_info(pubkey_or_secret) do
    pubkey_or_secret
    |> address()
    |> fetch_account_info()
  end

  # https://github.com/aeternity/protocol/blob/master/serializations.md#the-id-type
  [
    account: 1,
    name: 2,
    commitment: 3,
    oracle: 4,
    contract: 5,
    channel: 6
  ]
  |> Enum.map(fn {type, tag} ->
    defp id_type_to_tag(unquote(type)), do: unquote(tag)
    defp id_tag_to_type(unquote(tag)), do: unquote(type)
  end)

  # https://github.com/aeternity/protocol/blob/master/serializations.md#table-of-object-tags
  defp object_type_to_tag(:signed_tx), do: 11
  defp object_type_to_tag(:spend_tx), do: 12
end
