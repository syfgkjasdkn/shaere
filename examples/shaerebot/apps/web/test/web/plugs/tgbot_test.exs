defmodule Web.Plugs.TGBotTest do
  use Web.ConnCase

  test "invalid token", %{conn: conn} do
    conn = post(conn, "/tgbot/aksdjhfg")
    assert conn.status == 200
    assert_receive(:invalid_token)
    refute_receive {:message, _telegram_id, _text}
  end

  test "no token", %{conn: conn} do
    conn = post(conn, "/tgbot")
    assert conn.status == 200
    assert_receive(:invalid_token)
    refute_receive {:message, _telegram_id, _text}
  end

  test "valid token", %{conn: conn} do
    conn =
      post(conn, "/tgbot/#{TGBot.token()}", %{
        "message" => %{
          "text" => "/help",
          "from" => %{"id" => 123},
          "chat" => %{"id" => 123, "type" => "private"}
        }
      })

    assert conn.status == 200

    assert_receive {:message,
                    telegram_id: 123,
                    text: """
                    /shaere <amount> <address> to share some Æ

                    /key to get your private key

                    /address to get your address

                    /balance to get your balance

                    /help to get this message
                    """}
  end
end
