defmodule Shaere.TestAeAdapter do
  @moduledoc false
  @behaviour Shaere.AeAdapterType

  @balances %{
    125 => 1000
  }

  @impl true
  def balance(telegram_id) do
    @balances[telegram_id] || 0
  end

  @impl true
  def shaere(<<sender_privkey::64-bytes>>, "ak_" <> _rest = receiver, amount) do
    send(self(), {:shaere, sender_privkey: sender_privkey, receiver: receiver, amount: amount})
    {:ok, "th_2F1SLzAAKGYhbA52NfvX3XCVnTYjewgKeoXdFQawMKA1ScmQ2g"}
  end
end
