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
         "from" => %{"id" => sender_id, "username" => sender_username},
         "reply_to_message" => %{
           "from" => %{"id" => receiver_id, "username" => receiver_username}
         }
       }) do
    case Integer.parse(amount) do
      {amount, _rest} ->
        case Core.shaere(sender_id, receiver_id, amount) do
          {:ok, th} ->
            @adapter.send_message(
              chat_id,
              """
              👍

              Sent #{amount} AE from @#{sender_username} to @#{receiver_username}

              Tx: *#{th}*
              """
            )

            # TODO error case
        end

      _other ->
        @adapter.send_message(chat_id, "🚨 Couldn't parse #{amount} as an integer!")
    end
  end

  defp handle_public("/shaere " <> amount_and_address, %{
         "chat" => %{"id" => chat_id},
         "from" => %{"id" => sender_id, "username" => sender_username}
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
                  """
                  👍

                  Sent #{amount} AE from @#{sender_username} to *#{address}*

                  Tx: *#{th}*
                  """
                )

                # TODO error case
            end

          _other ->
            @adapter.send_message(chat_id, "🚨 Couldn't parse #{amount} as an integer!")
        end

      _other ->
        @adapter.send_message(chat_id, """
        🚨 Couldn't parse #{amount_and_address} as <amount> <address>
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

  @private_help_msg """
  /shaere <amount> <address> to share some AE

  /key to get your private key

  /address to get your address

  /balance to get your balance

  /help to get this message
  """

  defp handle_private("/shaere", %{"chat" => %{"id" => chat_id}}) do
    @adapter.send_message(chat_id, """
    /shaere <amount> <address>

    Example:

    /shaere 100 ak_2kzfp48mXUDda1tVLeNaYDKM9gPMcpYJhcUXmawKoPYgfbopVs

    You can also just reply to someone's message with /shaere <amount> in a public room.
    """)
  end

  defp handle_private("/shaere " <> amount_and_address, %{"chat" => %{"id" => chat_id}}) do
    case String.split(amount_and_address) do
      [amount, "ak_" <> _rest = address] ->
        case Integer.parse(amount) do
          # TODO validate address
          {amount, _rest} ->
            case Core.shaere(chat_id, address, amount) do
              {:ok, th} ->
                @adapter.send_message(
                  chat_id,
                  """
                  👍

                  Sent #{amount} AE to *#{address}*

                  Tx: *#{th}*
                  """
                )

                # TODO error case
            end

          _other ->
            @adapter.send_message(chat_id, "🚨 Couldn't parse #{amount} as an integer!")
        end

      _other ->
        @adapter.send_message(chat_id, """
        🚨 Couldn't parse #{amount_and_address} as <amount> <address>
        """)
    end
  end

  # TODO ensure chat_id == from_id
  defp handle_private("/help" <> _maybe_whitespace, %{"chat" => %{"id" => chat_id}}) do
    @adapter.send_message(chat_id, @private_help_msg)
  end

  defp handle_private("/balance" <> _maybe_whitespace, %{"chat" => %{"id" => chat_id}}) do
    balance = Core.balance(chat_id)

    @adapter.send_message(
      chat_id,
      """
      Your balance is *#{balance} AE.*

      Try to keep the funds here to a minimum. Think of it like pocket change.
      """,
      parse_mode: "Markdown"
    )
  end

  defp handle_private("/key" <> _maybe_whitespace, %{"chat" => %{"id" => chat_id}}) do
    privkey = Core.privkey(chat_id)

    @adapter.send_message(
      chat_id,
      """
      Your private key is *#{Base.encode16(privkey, case: :lower)}*
      """,
      parse_mode: "Markdown"
    )
  end

  defp handle_private("/address" <> _maybe_whitespace, %{"chat" => %{"id" => chat_id}}) do
    address = Core.address(chat_id)

    @adapter.send_message(
      chat_id,
      """
      Your address is *#{address}*
      """,
      parse_mode: "Markdown"
    )
  end

  defp handle_private("/start" <> _maybe_whitespace, %{"chat" => %{"id" => chat_id}}) do
    address = Core.address(chat_id)

    private_start_msg = [
      """
      <b>Wake up,</b> we're here. <i>Why are you shaking?</i> Are you ok? <b>Wake up.</b>

      Stand up ... there you go. You were dreaming. What's your Æternity ™ /address?

      Shhh ... Let me guess, is it <b>\
      """,
      address,
      """
      ?</b>

      Oh, nevermind, I have psychic powers. I heard them say we're soon to reach Mainnet, until then you can top up your /balance on https://edge-faucet.aepps.com/.

      Quiet, here comes the guard. Don't worry, I'll be around to /help you.

      But you better do what they say!

      And they say /shaere!
      """
    ]

    @adapter.send_message(chat_id, private_start_msg, parse_mode: "HTML")
  end

  defp handle_private(_other, %{"chat" => %{"id" => chat_id}}) do
    @adapter.send_message(chat_id, @private_help_msg)
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
