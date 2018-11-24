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
    # TODO send the tx
    @adapter.send_message(chat_id, "ok, sent #{amount} AE from #{sender_id} to #{receiver_id}")
  end

  defp handle_public("/shaere " <> amount_and_address, %{
         "chat" => %{"id" => chat_id},
         "from" => %{"id" => sender_id}
       }) do
    # TODO
    [amount, address] = String.split(amount_and_address)
    @adapter.send_message(chat_id, "ok, sent #{amount} AE from #{sender_id} to #{address}")
  end

  # TODO unmatched /shaere

  # TODO tell about testnet (not mainnet)
  @private_help_msg "TODO"

  defp handle_private("/help" <> _maybe_whitespace, %{"chat" => %{"id" => chat_id}}) do
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
