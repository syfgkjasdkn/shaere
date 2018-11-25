defmodule ShaereTest do
  use ExUnit.Case

  setup_all do
    {:ok, _pid} = Shaere.TestStorage.start_link([])
    :ok = Shaere.set_storage_adapter(Shaere.TestStorage)

    :ok
  end

  setup do
    true = Shaere.TestStorage.clean()

    :ok
  end

  test "privkey/1" do
    telegram_id = 123
    refute Shaere.TestStorage.lookup(telegram_id)

    assert privkey = Shaere.privkey(telegram_id)
    assert byte_size(privkey) == 64

    assert privkey == Shaere.TestStorage.lookup(telegram_id)
  end

  test "balance/1" do
    empty_telegram_id = 124
    telegram_id = 125

    assert 0 == Shaere.balance(empty_telegram_id)
    assert 1000 == Shaere.balance(telegram_id)
  end

  test "address/1" do
    telegram_id = 125

    assert privkey = Shaere.privkey(telegram_id)
    assert Shaere.Ae.address(privkey) == Shaere.address(telegram_id)
  end

  describe "share/3" do
    test "with address" do
      sender_telegram_id = 125

      assert {:ok, _th} =
               Shaere.shaere(
                 sender_telegram_id,
                 "ak_2okXACqGyq8JMLYgj3okriUVHktecxfzzdzX7cuma4wMFUXntU",
                 666
               )

      assert_receive {:shaere,
                      sender_privkey: sender_privkey,
                      receiver: "ak_2okXACqGyq8JMLYgj3okriUVHktecxfzzdzX7cuma4wMFUXntU",
                      amount: 666}

      assert sender_privkey == Shaere.TestStorage.lookup(125)
    end

    test "with telegram id" do
      sender_telegram_id = 126
      to_telegram_id = 127

      assert {:ok, _th} =
               Shaere.shaere(
                 sender_telegram_id,
                 to_telegram_id,
                 666
               )

      assert_receive {:shaere, sender_privkey: sender_privkey, receiver: receiver, amount: 666}

      assert sender_privkey == Shaere.TestStorage.lookup(126)
      assert receiver == Shaere.address(127)
    end
  end
end
