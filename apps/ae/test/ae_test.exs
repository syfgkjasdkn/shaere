defmodule AeTest do
  use ExUnit.Case
  doctest Ae, import: true

  @privkey Base.decode64!(
             "qhNlWAQvuPUshZCluV1R55yDCL11FHw71KxpsU2o//Tt2TVtM2R6/MqJTcXHg/1VDzIMwq3HagCcOkvIe9ziRQ",
             padding: false
           )

  test "keypair/0" do
    assert %{public: <<_pubkey::32-bytes>>, secret: <<_privkey::64-bytes>>} = Ae.keypair()
  end

  test "public_key/1" do
    assert %{public: <<pubkey::32-bytes>>, secret: <<privkey::64-bytes>>} = Ae.keypair()
    assert pubkey == Ae.public_key(privkey)
  end

  test "sign/2" do
    <<privkey::64-bytes>> = @privkey

    assert Ae.sign("hello", privkey) ==
             Base.decode64!(
               "plZF5adLtkqy2HTN8Lt2fYfT4MK6GOO7GVFW+jdceEq7Gx3RpJwYju+JJYhBOiXvrvzQSp72R7T+9kjys2qcAA",
               padding: false
             )
  end

  describe "address" do
    test "from privkey" do
      <<privkey::64-bytes>> = @privkey
      assert Ae.address(privkey) == "ak_2okXACqGyq8JMLYgj3okriUVHktecxfzzdzX7cuma4wMFUXntU"
    end

    test "from pubkey" do
      <<privkey::64-bytes>> = @privkey
      pubkey = Ae.public_key(privkey)
      assert Ae.address(pubkey) == "ak_2okXACqGyq8JMLYgj3okriUVHktecxfzzdzX7cuma4wMFUXntU"
    end
  end
end
