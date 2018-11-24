defmodule TGBotTest do
  use ExUnit.Case

  setup do
    flush_messages()
    true = Core.Storage.clean()

    :ok
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

      send_public_message(
        telegram_id,
        "/shaere 100 ak_2okXACqGyq8JMLYgj3okriUVHktecxfzzdzX7cuma4wMFUXntU"
      )

      assert_receive {:shaere,
                      sender_privkey: sender_privkey,
                      receiver: "ak_2okXACqGyq8JMLYgj3okriUVHktecxfzzdzX7cuma4wMFUXntU",
                      amount: 100}

      assert sender_privkey == Core.privkey(telegram_id)

      assert_receive {:message,
                      telegram_id: ^telegram_id,
                      text:
                        "ok, sent 100 AE from 1001 to ak_2okXACqGyq8JMLYgj3okriUVHktecxfzzdzX7cuma4wMFUXntU, th: th_2F1SLzAAKGYhbA52NfvX3XCVnTYjewgKeoXdFQawMKA1ScmQ2g"}
    end

    test "shaere with reply" do
      telegram_id = 1002
      send_public_reply(telegram_id, "/shaere 105")

      assert_receive {:shaere, sender_privkey: sender_privkey, receiver: receiver, amount: 105}

      assert sender_privkey == Core.privkey(telegram_id)
      assert receiver == Core.address(1234)

      assert_receive {:message,
                      telegram_id: ^telegram_id,
                      text:
                        "ok, sent 105 AE from 1002 to 1234, th: th_2F1SLzAAKGYhbA52NfvX3XCVnTYjewgKeoXdFQawMKA1ScmQ2g"}
    end

    test "shaere help" do
      telegram_id = 1006
      send_public_reply(telegram_id, "/shaere")

      assert_receive {:message,
                      telegram_id: ^telegram_id,
                      text: """
                      /shaere <amount> <address>

                      or, if you reply to other message, just

                      /shaere <amount>
                      """}
    end

    test "invalid shaere" do
      # telegram_id = 1007
      # TODO
    end
  end

  describe "private" do
    test "help" do
      telegram_id = 1003
      send_private_message(telegram_id, "/help")

      assert_receive {:message,
                      telegram_id: ^telegram_id,
                      text: """
                      /shaere <amount> <address> to share some AE

                      /key to get your private key

                      /address to get your address

                      /balance to get your balance

                      /help to get help
                      """}
    end

    test "balance" do
      empty_telegram_id = 124
      telegram_id = 125

      assert 0 == Core.balance(empty_telegram_id)
      assert 1000 == Core.balance(telegram_id)

      send_private_message(empty_telegram_id, "/balance")

      assert_receive {:message,
                      telegram_id: ^empty_telegram_id,
                      text: """
                      Your balance is 0 AE.
                      """}

      send_private_message(telegram_id, "/balance")

      assert_receive {:message,
                      telegram_id: ^telegram_id,
                      text: """
                      Your balance is 1000 AE.
                      """}
    end

    test "privkey" do
      telegram_id = 12345

      send_private_message(telegram_id, "/key")

      privkey = Core.privkey(telegram_id)

      privkey_base16 = Base.encode16(privkey, case: :lower)

      assert_receive {:message, telegram_id: ^telegram_id, text: text}

      assert text == """
             Your private key is #{privkey_base16}.
             """
    end

    test "address" do
      telegram_id = 12346

      send_private_message(telegram_id, "/address")

      address = Core.address(telegram_id)

      assert_receive {:message, telegram_id: ^telegram_id, text: text}

      assert text == """
             Your address is #{address}.
             """
    end

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
