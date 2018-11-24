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

  test "balance/1"

  test "address/1" do
    telegram_id = 125

    assert privkey = Core.privkey(telegram_id)
    assert Ae.address(privkey) == Core.address(telegram_id)
  end

  describe "share/3" do
    test "with address"

    test "with telegram id"
  end
end
