defmodule TGBot.NadiaAdapter do
  @moduledoc false
  @behaviour TGBot.Adapter

  @impl true
  def send_message(telegram_id, text, opts \\ []) do
    Nadia.send_message(telegram_id, text, opts)
  end

  @impl true
  def set_webhook(url) do
    Nadia.set_webhook(url: url)
  end
end
