defmodule TGBot.TestAdapter do
  @moduledoc false
  @behaviour TGBot.Adapter

  @impl true
  def send_message(telegram_id, text, opts \\ []) do
    send(self(), {:message, telegram_id: telegram_id, text: text})
  end

  @impl true
  def set_webhook(url) do
    send(self(), {:webhook, url: url})
  end
end
