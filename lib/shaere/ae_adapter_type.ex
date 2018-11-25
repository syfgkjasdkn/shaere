defmodule Shaere.AeAdapterType do
  @moduledoc false

  @callback balance(telegram_id :: pos_integer) :: non_neg_integer
  @callback shaere(sender_privkey :: Shaere.Ae.secret(), receiver :: String.t(),
              amount: pos_integer
            ) :: {:ok, th :: binary} | {:error, any}
end
