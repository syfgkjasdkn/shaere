defmodule TGBotTest do
  use ExUnit.Case

  setup do
    flush_messages()
  end

  describe "public" do
    test "help" do
      telegram_id = 1000
      send_public_message(telegram_id, "/help")

      assert_receive {:message,
                      telegram_id: ^telegram_id,
                      text: """
                      👋

                      /shaere <amount> <address>

                      or, if you reply to other message, just

                      /shaere <amount>
                      """}
    end

    test "shaere with address" do
      telegram_id = 1001
      send_public_message(telegram_id, "/shaere 100 ak_8r637igefyuvblg36t72iweguy")

      assert_receive {:message,
                      telegram_id: ^telegram_id,
                      text: "ok, sent 100 AE from 1001 to ak_8r637igefyuvblg36t72iweguy"}
    end

    test "shaere with reply" do
      telegram_id = 1002
      send_public_reply(telegram_id, "/shaere 100")

      assert_receive {:message,
                      telegram_id: ^telegram_id, text: "ok, sent 100 AE from 1002 to 1234"}
    end
  end

  describe "private" do
    test "help" do
      telegram_id = 1003
      send_private_message(telegram_id, "/help")

      assert_receive {:message, telegram_id: ^telegram_id, text: "TODO"}
    end

    test "balance"

    test "privkey"

    test "address"

    test "shaere with address"
  end

  test "webhook" do
    TGBot.set_webhook("https://some.website/tgbot")

    assert_receive {:webhook,
                    url: "https://some.website/tgbot/1263745172:iugyaksdfhjfgrgyuwekfhjsdb"}
  end

  defp send_private_message(telegram_id, text) do
    TGBot.handle(%{
      "message" => %{
        "from" => %{"id" => telegram_id},
        "chat" => %{"id" => telegram_id, "type" => "private"},
        "text" => text
      }
    })
  end

  defp send_public_message(telegram_id, text) do
    TGBot.handle(%{
      "message" => %{
        "from" => %{"id" => telegram_id, "username" => "somebody"},
        "chat" => %{"id" => telegram_id, "type" => "supergroup"},
        "text" => text
      }
    })
  end

  defp send_public_reply(telegram_id, text) do
    TGBot.handle(%{
      "message" => %{
        "from" => %{"id" => telegram_id, "username" => "somebody"},
        "chat" => %{"id" => telegram_id, "type" => "supergroup"},
        "text" => text,
        "reply_to_message" => %{
          "from" => %{"id" => 1234, "username" => "somebody2"}
        }
      }
    })
  end

  defp flush_messages(timeout \\ 0) do
    receive do
      _message -> flush_messages()
    after
      timeout -> :ok
    end
  end
end
