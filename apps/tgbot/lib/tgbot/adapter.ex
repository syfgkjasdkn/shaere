defmodule TGBot.Adapter do
  @moduledoc false

  @callback send_message(telegram_id :: integer, String.t()) :: any

  @callback set_webhook(url :: String.t()) :: any
end
