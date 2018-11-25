defmodule Shaere.Ae do
  @moduledoc File.read!("README.md")

  @type public_key :: <<_::256>>
  @type secret :: <<_::512>>

  @default_tx_ttl 500
  @default_tx_fee 1
  @version 1
  @tag_size 8
  @hash_bytes_size 32

  @api_endpoint "https://sdk-testnet.aepps.com/v2"

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

  @spec spend_tx(secret, public_key, integer) :: map
  @spec spend_tx(secret, public_key, integer, Keyword.t()) :: map
  def spend_tx(<<sender_privkey::64-bytes>>, <<receiver_pubkey::32-bytes>>, amount, opts \\ []) do
    fee = opts[:fee] || @default_tx_fee
    payload = opts[:payload] || ""
    ttl = opts[:ttl] || _fetch_absolute_ttl(@default_tx_ttl)
    nonce = opts[:nonce] || _fetch_next_nonce(sender_privkey)

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

  @spec _fetch_next_nonce(public_key | secret | String.t()) :: pos_integer
  defp _fetch_next_nonce(account_id_or_key) do
    case fetch_account_info(account_id_or_key) do
      %{"nonce" => nonce} -> nonce + 1
      nil -> 1
    end
  end

  @spec _fetch_absolute_ttl(pos_integer) :: pos_integer
  defp _fetch_absolute_ttl(relative_ttl) do
    height =
      case fetch_latest_block() do
        %{"key_block" => %{"height" => height}} -> height
        %{"micro_block" => %{"height" => height}} -> height
      end

    height + relative_ttl
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
    case :httpc.request('#{@api_endpoint}/accounts/#{account}') do
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

  @doc """
  Fetches the top block. Returns something not quite unlike

      %{
        "key_block" => %{
          "beneficiary" => "ak_25MZX3BXYP32YDPGWsJqYZ6CgWnqD93VdpCYaTk6KsThEbeFJX",
          "hash" => "kh_2h15JFkVrdbezfbm7sLt1B4ib3cUbfc6ntuzDRBwPbDCQdJ21u",
          "height" => 7319,
          "miner" => "ak_2e1y67ed7wVN9XURPxTBkP8QmApHGx1TwKKPCxYMDqvv1zwAxh",
          "nonce" => 4115169287220855550,
          "pow" => [639, 1014, 1330, 1597, 3818, 6805, 7011, 7278, 8465, 8773, 9999,
           10823, 11256, 12339, 13874, 14191, 14573, 15166, 17190, 18252, 18640,
           18728, 19145, 19915, 20684, 20963, 21031, 21754, 22883, 23533, 24612,
           24657, 24787, 24973, 25518, 26498, 26815, 29443, 29922, 30134, 30275,
           31408],
          "prev_hash" => "kh_2MDBwH5bTW3RMQv9k2WDN8GW2q7QEwBMf3yXXkCmJTYkHtvoxF",
          "prev_key_hash" => "kh_2MDBwH5bTW3RMQv9k2WDN8GW2q7QEwBMf3yXXkCmJTYkHtvoxF",
          "state_hash" => "bs_CLHJB4Tsgjc4yZTVDmSivAm3JiVF5ZtkWqPKr7FjDNiXmHXd2",
          "target" => 536948372,
          "time" => 1543058259721,
          "version" => 28
        }
      }

  See http://aeternity.com/epoch-api-docs/?config=https://raw.githubusercontent.com/aeternity/epoch/master/apps/aehttp/priv/swagger.json#/external/GetTopBlock
  """
  @spec fetch_latest_block :: map
  def fetch_latest_block do
    {:ok, {{_version, 200, _description}, _resp_headers, resp_body}} =
      :httpc.request('#{@api_endpoint}/blocks/top')

    Jason.decode!(resp_body)
  end

  @doc """
  Fetches info about a transaction by its hash.

      %{
        "block_hash" => "mh_VWHWsJsCpsbzXyEo2TVCLB9H683SnJX7CoU3hywFwcGfxcN4X3i",
        "block_height" => -1,
        "hash" => "th_2F1SLzAAKGYhbA52NfvX3XCVnTYjewgKeoXdFQawMKA1ScmQ2g",
        "signatures" => ["sg_4Tf4pBZR2DLxiB9EA2ZKoWLtqyEqsGpK1R8RfwDetRPfhutbfKLe3XYQUxAKrWsopTzA8XDaQqcf1ArphQjec3ite1W9Q"],
        "tx" => %{
          "amount" => 50,
          "fee" => 1,
          "nonce" => 1,
          "payload" => "",
          "recipient_id" => "ak_25MZX3BXYP32YDPGWsJqYZ6CgWnqD93VdpCYaTk6KsThEbeFJX",
          "sender_id" => "ak_2okXACqGyq8JMLYgj3okriUVHktecxfzzdzX7cuma4wMFUXntU",
          "ttl" => 7829,
          "type" => "SpendTx",
          "version" => 1
        }
      }

  See http://aeternity.com/epoch-api-docs/?config=https://raw.githubusercontent.com/aeternity/epoch/master/apps/aehttp/priv/swagger.json#/external/GetTransactionByHash
  """
  @spec fetch_tx_info(String.t()) :: map | nil
  def fetch_tx_info("th_" <> _ = th) do
    case :httpc.request('#{@api_endpoint}/transactions/#{th}') do
      {:ok, {{_version, 200, _description}, _resp_headers, resp_body}} ->
        Jason.decode!(resp_body)

      {:ok, {{_version, 404, _description}, _resp_headers, _resp_body}} ->
        nil
    end
  end

  @doc """
  Posts a signed transaction, returns transaction's hash.

  See http://aeternity.com/epoch-api-docs/?config=https://raw.githubusercontent.com/aeternity/epoch/master/apps/aehttp/priv/swagger.json#/external/PostTransaction
  """
  @spec send_tx(String.t()) :: {:ok, map} | {:error, any}
  def send_tx("tx_" <> _rest = tx) do
    case :httpc.request(
           :post,
           {
             '#{@api_endpoint}/transactions',
             [],
             'application/json',
             # TODO
             to_charlist(Jason.encode!(%{"tx" => tx}))
           },
           [],
           []
         ) do
      {:ok, {{_version, 200, _description}, _resp_headers, resp_body}} ->
        {:ok, Jason.decode!(resp_body)}

      {:ok, {{_version, 400, _description}, _resp_headers, resp_body}} ->
        {:error, Jason.decode!(resp_body)}
    end
  end

  # https://github.com/aeternity/protocol/blob/master/serializations.md#the-id-type
  @spec id_type_to_tag(:account | :name | :commitment | :oracle | :contract | :channel) :: 1..6
  defp id_type_to_tag(type)

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
