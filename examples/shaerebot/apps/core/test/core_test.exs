defmodule CoreTest do
  use ExUnit.Case

  setup do
    true = Core.Storage.clean()

    :ok
  end

  test "privkey/1" do
    telegram_id = 123
    refute Core.Storage.lookup(telegram_id)

    assert privkey = Core.privkey(telegram_id)
    assert byte_size(privkey) == 64

    assert privkey == Core.Storage.lookup(telegram_id)
  end

  test "balance/1" do
    empty_telegram_id = 124
    telegram_id = 125

    assert 0 == Core.balance(empty_telegram_id)
    assert 1000 == Core.balance(telegram_id)
  end

  test "address/1" do
    telegram_id = 125

    assert privkey = Core.privkey(telegram_id)
    assert Ae.address(privkey) == Core.address(telegram_id)
  end

  describe "share/3" do
    test "with address" do
      sender_telegram_id = 125

      assert {:ok, _th} =
               Core.shaere(
                 sender_telegram_id,
                 "ak_2okXACqGyq8JMLYgj3okriUVHktecxfzzdzX7cuma4wMFUXntU",
                 666
               )

      assert_receive {:shaere,
                      sender_privkey: sender_privkey,
                      receiver: "ak_2okXACqGyq8JMLYgj3okriUVHktecxfzzdzX7cuma4wMFUXntU",
                      amount: 666}

      assert sender_privkey == Core.Storage.lookup(125)
    end

    test "with telegram id" do
      sender_telegram_id = 126
      to_telegram_id = 127

      assert {:ok, _th} =
               Core.shaere(
                 sender_telegram_id,
                 to_telegram_id,
                 666
               )

      assert_receive {:shaere, sender_privkey: sender_privkey, receiver: receiver, amount: 666}

      assert sender_privkey == Core.Storage.lookup(126)
      assert receiver == Core.address(127)
    end
  end
end
