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

  describe "spend_tx" do
    test "against /debug/transactions/spend" do
      # curl -X POST "https://sdk-edgenet.aepps.com/v2/debug/transactions/spend" \
      #      -H "accept: application/json" -H "Content-Type: application/json" \
      #      -d "{\"amount\": 50, \"payload\": \"payload\", \"fee\": 6, \"ttl\": 1, \"nonce\": 1, \"sender_id\": \"ak_2okXACqGyq8JMLYgj3okriUVHktecxfzzdzX7cuma4wMFUXntU\", \"recipient_id\": \"ak_25MZX3BXYP32YDPGWsJqYZ6CgWnqD93VdpCYaTk6KsThEbeFJX\"}"

      # responds with 
      # {"tx":"tx_2zsGHju8n9gN4gQRXrHkafTrFCLmXDq2if9sw7zzwHkVQd4ktvHHimkBAqSFMCQHwTsnw8X2YF3VWVefNDJNeFnJyTocT6FxuVYAQuUGgYmB4ishZUJUwaTgc"}

      # corresponds to ak_2okXACqGyq8JMLYgj3okriUVHktecxfzzdzX7cuma4wMFUXntU
      <<sender_privkey::64-bytes>> = @privkey

      "ak_" <> recipient_pubkey_base58c = "ak_25MZX3BXYP32YDPGWsJqYZ6CgWnqD93VdpCYaTk6KsThEbeFJX"
      recipient_pubkey = Ae.decode58c(recipient_pubkey_base58c)

      spend_tx =
        Ae.spend_tx(sender_privkey, recipient_pubkey, 50,
          fee: 6,
          payload: "payload",
          ttl: 1,
          nonce: 1
        )

      spend_tx_list = Ae.encode_spend_tx_to_list(spend_tx)

      assert [
               "\f",
               <<1>>,
               <<1, 237, 217, 53, 109, 51, 100, 122, 252, 202, 137, 77, 197, 199, 131, 253, 85,
                 15, 50, 12, 194, 173, 199, 106, 0, 156, 58, 75, 200, 123, 220, 226, 69>>,
               <<1, 141, 149, 96, 177, 205, 123, 203, 249, 252, 223, 45, 101, 59, 117, 245, 217,
                 234, 12, 202, 101, 50, 214, 96, 208, 146, 81, 114, 86, 228, 38, 240, 171>>,
               "2",
               <<6>>,
               <<1>>,
               <<1>>,
               "payload"
             ] == spend_tx_list

      spend_tx_rlp = ExRLP.encode(spend_tx_list)

      assert Ae.encode58c("tx", spend_tx_rlp) ==
               "tx_2zsGHju8n9gN4gQRXrHkafTrFCLmXDq2if9sw7zzwHkVQd4ktvHHimkBAqSFMCQHwTsnw8X2YF3VWVefNDJNeFnJyTocT6FxuVYAQuUGgYmB4ishZUJUwaTgc"
    end
  end

  describe "signed tx" do
    test "against python sdk" do
      # https://github.com/aeternity/aepp-sdk-python

      sender_privkey_base16 =
        "2066706da5cd53d50d74010bf4623fbefba85cddd3fe62da126ba2c564ad7658db1f68a77317bb481a02e32d4fede64e9526c60af25a14259744fe72a7d3f149"

      sender_privkey = Base.decode16!(sender_privkey_base16, case: :lower)
      sender_address = Ae.address(sender_privkey)

      assert sender_address == "ak_2fWCK7QRfcRNcufGPNpNefoNTeuGobUav4AHQVD7kQffsUjck6"

      "ak_" <> recipient_pubkey_base58c = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      recipient_pubkey = Ae.decode58c(recipient_pubkey_base58c)

      spend_tx = Ae.spend_tx(sender_privkey, recipient_pubkey, 50, ttl: 7389, nonce: 3)

      expected_spend_tx_list = [
        "\f",
        <<1>>,
        <<1, 219, 31, 104, 167, 115, 23, 187, 72, 26, 2, 227, 45, 79, 237, 230, 78, 149, 38, 198,
          10, 242, 90, 20, 37, 151, 68, 254, 114, 167, 211, 241, 73>>,
        <<1, 11, 180, 237, 121, 39, 249, 123, 81, 225, 188, 181, 225, 52, 13, 18, 51, 91, 42, 43,
          18, 200, 188, 82, 33, 214, 60, 75, 203, 57, 212, 30, 97>>,
        "2",
        <<1>>,
        <<28, 221>>,
        <<3>>,
        ""
      ]

      spend_tx_list = Ae.encode_spend_tx_to_list(spend_tx)

      assert expected_spend_tx_list == spend_tx_list

      expected_rlp =
        Base.decode16!(
          "f84d0c01a101db1f68a77317bb481a02e32d4fede64e9526c60af25a14259744fe72a7d3f149a1010bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e613201821cdd0380",
          case: :lower
        )

      spend_tx_rlp = ExRLP.encode(spend_tx_list)

      assert expected_rlp == spend_tx_rlp

      expected_signature =
        Base.decode16!(
          "d9e148a2bdbc33631471be004f3b850a9022af518a3e3affd1188c818f2f2fe3d271a8f8053d3942739c298368cb370e00d01b25126ee5a901090fa8d1095209",
          case: :lower
        )

      signature = Ae.sign("ae_mainnet" <> spend_tx_rlp, sender_privkey)

      assert signature == expected_signature

      assert signature == Ae.sign_tx(spend_tx, sender_privkey)

      expected_signature_base58 =
        "sg_VWHWsJsCpsbzXyEo2TVCLB9H683SnJX7CoU3hywFwcGfxcN4X3iLsAge7x29SP8nqq873iQr2wuZtJL37hEhyvG7BRWcQ"

      assert Ae.encode58c("sg", signature) == expected_signature_base58

      expected_unsigned_tx =
        "tx_51fEeKes5rtuJ1uvBYQGBrhFzC4S922P3CAvqLXLcRSQmZPScmLP4J7YH1extUkab81NBwwMEpRHMyAgc8pFBntC1vUbCh3BbjuDBvyS1x4tePaiwS"

      assert Ae.encode58c("tx", spend_tx_rlp) == expected_unsigned_tx

      expected_signed_tx =
        "tx_66dpehQZhw1tYk7nxeoKkGEmr5tNxcXtFna8gFT1SN7PyL2PZfNZJSXVtFQWvneaJmNq8Qv4oeW2NFMLGGqYPGaVBfD46w8nGdVFZpeBDMX2wCTPSbyLZfmAWHkAqVsee5HCKjgyCttFFMGg1chRjj7nwq6T421Cg6zY73hNV1rJKUo5JH4fL7nLr5wdcsjRuV6SEeXsiJPAV2JTktAhwdd"

      signed_rlp = spend_tx |> Ae.encode_signed_tx_to_list([signature]) |> ExRLP.encode()
      assert Ae.encode58c("tx", signed_rlp) == expected_signed_tx

      expected_hash = "th_WXmYVFfpTZYSWGM6kSruERzrqvTGbbwnPerfCmuESprQP2yuM"

      assert Ae.encode58c("th", Ae.hash_tx(spend_tx, [signature])) == expected_hash
    end
  end
end
