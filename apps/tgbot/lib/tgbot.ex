defmodule TGBot do
  @moduledoc File.read!("README.md")
  @adapter Application.get_env(:tgbot, :adapter) || raise("need tgbot adapter set")

  # TODO spec
  def handle(request)

  def handle(%{
        "message" =>
          %{
            "chat" => %{"type" => chat_type},
            "text" => text
          } = message
      })
      when chat_type in ["group", "supergroup", "channel"] do
    handle_public(text, message)
  end

  def handle(%{
        "message" =>
          %{
            "chat" => %{"type" => "private"},
            "text" => text
          } = message
      }) do
    handle_private(text, message)
  end

  def handle(_other) do
    :ignore
  end

  @public_help_msg """
  👋

  /shaere <amount> <address>

  or, if you reply to other message, just

  /shaere <amount>
  """

  # TODO spec
  defp handle_public("/help" <> _maybe_whitespace, %{"chat" => %{"id" => chat_id}}) do
    @adapter.send_message(chat_id, @public_help_msg)
  end

  defp handle_public("/shaere " <> amount, %{
         "chat" => %{"id" => chat_id},
         "from" => %{"id" => sender_id},
         "reply_to_message" => %{
           "from" => %{"id" => receiver_id}
         }
       }) do
    case Integer.parse(amount) do
      {amount, _rest} ->
        case Core.shaere(sender_id, receiver_id, amount) do
          {:ok, th} ->
            @adapter.send_message(
              chat_id,
              "ok, sent #{amount} AE from #{sender_id} to #{receiver_id}, th: #{th}"
            )

            # TODO error case
        end

      _other ->
        @adapter.send_message(chat_id, "couldn't parse #{amount} as an integer")
    end
  end

  defp handle_public("/shaere " <> amount_and_address, %{
         "chat" => %{"id" => chat_id},
         "from" => %{"id" => sender_id}
       }) do
    case String.split(amount_and_address) do
      [amount, "ak_" <> _rest = address] ->
        case Integer.parse(amount) do
          # TODO validate address
          {amount, _rest} ->
            case Core.shaere(sender_id, address, amount) do
              {:ok, th} ->
                @adapter.send_message(
                  chat_id,
                  "ok, sent #{amount} AE from #{sender_id} to #{address}, th: #{th}"
                )

                # TODO error case
            end

          _other ->
            @adapter.send_message(chat_id, "couldn't parse #{amount} as an integer")
        end

      _other ->
        @adapter.send_message(chat_id, """
        couldn't parse amount and address

        /shaere <amount> <address>

        or, if you reply to other message, just

        /shaere <amount>
        """)
    end
  end

  defp handle_public("/shaere", %{"chat" => %{"id" => chat_id}}) do
    @adapter.send_message(chat_id, """
    /shaere <amount> <address>

    or, if you reply to other message, just

    /shaere <amount>
    """)
  end

  # TODO tell about testnet (not mainnet)
  @private_help_msg """
  /shaere <amount> <address> to share some AE

  /key to get your private key

  /address to get your address

  /balance to get your balance

  /help to get help
  """

  # TODO ensure chat_id == from_id
  defp handle_private("/help" <> _maybe_whitespace, %{"chat" => %{"id" => chat_id}}) do
    @adapter.send_message(chat_id, @private_help_msg)
  end

  defp handle_private("/balance" <> _maybe_whitespace, %{"chat" => %{"id" => chat_id}}) do
    balance = Core.balance(chat_id)

    @adapter.send_message(chat_id, """
    Your balance is #{balance} AE.
    """)
  end

  defp handle_private("/key" <> _maybe_whitespace, %{"chat" => %{"id" => chat_id}}) do
    privkey = Core.privkey(chat_id)

    @adapter.send_message(chat_id, """
    Your private key is #{Base.encode16(privkey, case: :lower)}.
    """)
  end

  defp handle_private("/address" <> _maybe_whitespace, %{"chat" => %{"id" => chat_id}}) do
    address = Core.address(chat_id)

    @adapter.send_message(chat_id, """
    Your address is #{address}.
    """)
  end

  @spec token :: String.t() | nil
  def token do
    Application.get_env(:nadia, :token)
  end

  # TODO spec
  def set_webhook(url) do
    url
    |> Path.join(token())
    |> @adapter.set_webhook()
  end
end
