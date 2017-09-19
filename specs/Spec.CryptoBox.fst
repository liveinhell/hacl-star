module Spec.CryptoBox

open FStar.Seq
open FStar.Endianness
open FStar.HyperStack (* Only for the RNG *)
open FStar.HyperStack.ST (* Only for the RNG *)

type bytes = seq UInt8.t

let dh_keylen = Spec.Curve25519.scalar_length (* in bytes *)
let keylen =   Spec.SecretBox.keylen (* in bytes *)
let noncelen = Spec.SecretBox.noncelen (* in bytes *)

type key = lbytes keylen (* = Spec.SecretBox.key *)
type dh_pkey = lbytes keylen (* = Spec.Curve25519.serialized_point *)
type dh_skey = lbytes keylen (* = Spec.Curve25519.scalar *)
type nonce = lbytes noncelen (* = Spec.SecretBox.nonce *)
type plain = Spec.SecretBox.plain
type cipher = Spec.SecretBox.cipher

(* Nonce for use in HSalsa20. Not the same as Spec.SecretBox.nonce *)
private let h_zero_nonce = Seq.create Spec.HSalsa20.noncelen (UInt8.uint_to_t 0)

#set-options "--z3rlimit 1000"
//val keygen: unit -> Stack (dh_pkey*dh_skey)
//  (requires (fun h0 -> True))
//  (ensures (fun h0 _ h1 ->
//    modifies Set.empty h0 h1
//  ))
//let keygen() =
//  let dh_exponent = Crypto.Symmetric.Bytes.random_bytes (UInt32.uint_to_t Spec.Curve25519.scalar_length) in
//  let dh_share = Spec.Curve25519.scalarmult dh_exponent Spec.Curve25519.base_point in
//  dh_share,dh_exponent


val public_from_secret: dh_skey -> dh_pkey
let public_from_secret sk =
  Spec.Curve25519.scalarmult sk Spec.Curve25519.base_point

val cryptobox_beforenm: pk:dh_pkey
          -> sk:dh_skey
          -> Tot (k:key)
let cryptobox_beforenm pk sk =
  let s = Spec.Curve25519.scalarmult sk pk in
  Spec.HSalsa20.hsalsa20 s h_zero_nonce

val cryptobox_afternm: p:plain
         -> n:nonce
         -> k:key
         -> Tot (c:cipher{Seq.length c = Seq.length p + 16})
let cryptobox_afternm m n k =
  Spec.SecretBox.secretbox_easy m k n

val cryptobox: p:plain
       -> n:nonce
       -> pk:dh_pkey
       -> sk:dh_skey
       -> Tot (c:cipher{Seq.length c = Seq.length p + 16})
let cryptobox m n pk sk =
  let k = cryptobox_beforenm pk sk in
  cryptobox_afternm m n k

#set-options "--z3rlimit 1000"
val cryptobox_open_afternm: c:cipher
        -> n:nonce
        -> k:key
        -> Tot (option (p:plain{Seq.length p = Seq.length c - 16}))
let cryptobox_open_afternm c n k =
  Spec.SecretBox.secretbox_open_easy c k n

val cryptobox_open: c:cipher
      -> n:nonce
      -> pk:dh_pkey
      -> (sk:dh_skey)
      -> Tot (option (p:plain{Seq.length p = Seq.length c - 16}))
let cryptobox_open c n pk sk =
  let k = cryptobox_beforenm pk sk in
  cryptobox_open_afternm c n k

(* Tests: https://cr.yp.to/highspeed/naclcrypto-20090310.pdf *)
unfold let k = [
        0x1buy;0x27uy;0x55uy;0x64uy;0x73uy;0xe9uy;0x85uy;0xd4uy;
        0x62uy;0xcduy;0x51uy;0x19uy;0x7auy;0x9auy;0x46uy;0xc7uy;
        0x60uy;0x09uy;0x54uy;0x9euy;0xacuy;0x64uy;0x74uy;0xf2uy;
        0x06uy;0xc4uy;0xeeuy;0x08uy;0x44uy;0xf6uy;0x83uy;0x89uy]

unfold let n = [
        0x69uy;0x69uy;0x6euy;0xe9uy;0x55uy;0xb6uy;0x2buy;0x73uy;
  0xcduy;0x62uy;0xbduy;0xa8uy;0x75uy;0xfcuy;0x73uy;0xd6uy;
  0x82uy;0x19uy;0xe0uy;0x03uy;0x6buy;0x7auy;0x0buy;0x37uy]

unfold let p = [
      0xbeuy;0x07uy;0x5fuy;0xc5uy;0x3cuy;0x81uy;0xf2uy;0xd5uy;
  0xcfuy;0x14uy;0x13uy;0x16uy;0xebuy;0xebuy;0x0cuy;0x7buy;
  0x52uy;0x28uy;0xc5uy;0x2auy;0x4cuy;0x62uy;0xcbuy;0xd4uy;
  0x4buy;0x66uy;0x84uy;0x9buy;0x64uy;0x24uy;0x4fuy;0xfcuy;
  0xe5uy;0xecuy;0xbauy;0xafuy;0x33uy;0xbduy;0x75uy;0x1auy;
  0x1auy;0xc7uy;0x28uy;0xd4uy;0x5euy;0x6cuy;0x61uy;0x29uy;
  0x6cuy;0xdcuy;0x3cuy;0x01uy;0x23uy;0x35uy;0x61uy;0xf4uy;
  0x1duy;0xb6uy;0x6cuy;0xceuy;0x31uy;0x4auy;0xdbuy;0x31uy;
  0x0euy;0x3buy;0xe8uy;0x25uy;0x0cuy;0x46uy;0xf0uy;0x6duy;
  0xceuy;0xeauy;0x3auy;0x7fuy;0xa1uy;0x34uy;0x80uy;0x57uy;
  0xe2uy;0xf6uy;0x55uy;0x6auy;0xd6uy;0xb1uy;0x31uy;0x8auy;
  0x02uy;0x4auy;0x83uy;0x8fuy;0x21uy;0xafuy;0x1fuy;0xdeuy;
  0x04uy;0x89uy;0x77uy;0xebuy;0x48uy;0xf5uy;0x9fuy;0xfduy;
  0x49uy;0x24uy;0xcauy;0x1cuy;0x60uy;0x90uy;0x2euy;0x52uy;
  0xf0uy;0xa0uy;0x89uy;0xbcuy;0x76uy;0x89uy;0x70uy;0x40uy;
  0xe0uy;0x82uy;0xf9uy;0x37uy;0x76uy;0x38uy;0x48uy;0x64uy;
  0x5euy;0x07uy;0x05uy]

unfold let alicesk = [
        0x77uy;0x07uy;0x6duy;0x0auy;0x73uy;0x18uy;0xa5uy;0x7duy;
  0x3cuy;0x16uy;0xc1uy;0x72uy;0x51uy;0xb2uy;0x66uy;0x45uy;
  0xdfuy;0x4cuy;0x2fuy;0x87uy;0xebuy;0xc0uy;0x99uy;0x2auy;
  0xb1uy;0x77uy;0xfbuy;0xa5uy;0x1duy;0xb9uy;0x2cuy;0x2auy]

unfold let alicepk = [
        0x85uy;0x20uy;0xf0uy;0x09uy;0x89uy;0x30uy;0xa7uy;0x54uy;
  0x74uy;0x8buy;0x7duy;0xdcuy;0xb4uy;0x3euy;0xf7uy;0x5auy;
  0x0duy;0xbfuy;0x3auy;0x0duy;0x26uy;0x38uy;0x1auy;0xf4uy;
  0xebuy;0xa4uy;0xa9uy;0x8euy;0xaauy;0x9buy;0x4euy;0x6auy]

unfold let bobpk = [
        0xdeuy;0x9euy;0xdbuy;0x7duy;0x7buy;0x7duy;0xc1uy;0xb4uy;
  0xd3uy;0x5buy;0x61uy;0xc2uy;0xecuy;0xe4uy;0x35uy;0x37uy;
  0x3fuy;0x83uy;0x43uy;0xc8uy;0x5buy;0x78uy;0x67uy;0x4duy;
  0xaduy;0xfcuy;0x7euy;0x14uy;0x6fuy;0x88uy;0x2buy;0x4fuy]

unfold let bobsk = [
        0x5duy;0xabuy;0x08uy;0x7euy;0x62uy;0x4auy;0x8auy;0x4buy;
  0x79uy;0xe1uy;0x7fuy;0x8buy;0x83uy;0x80uy;0x0euy;0xe6uy;
  0x6fuy;0x3buy;0xb1uy;0x29uy;0x26uy;0x18uy;0xb6uy;0xfduy;
  0x1cuy;0x2fuy;0x8buy;0x27uy;0xffuy;0x88uy;0xe0uy;0xebuy]

unfold let mac_and_cipher = [
        0xf3uy;0xffuy;0xc7uy;0x70uy;0x3fuy;0x94uy;0x00uy;0xe5uy;
      0x2auy;0x7duy;0xfbuy;0x4buy;0x3duy;0x33uy;0x05uy;0xd9uy;
        0x8euy;0x99uy;0x3buy;0x9fuy;0x48uy;0x68uy;0x12uy;0x73uy;
  0xc2uy;0x96uy;0x50uy;0xbauy;0x32uy;0xfcuy;0x76uy;0xceuy;
  0x48uy;0x33uy;0x2euy;0xa7uy;0x16uy;0x4duy;0x96uy;0xa4uy;
  0x47uy;0x6fuy;0xb8uy;0xc5uy;0x31uy;0xa1uy;0x18uy;0x6auy;
  0xc0uy;0xdfuy;0xc1uy;0x7cuy;0x98uy;0xdcuy;0xe8uy;0x7buy;
  0x4duy;0xa7uy;0xf0uy;0x11uy;0xecuy;0x48uy;0xc9uy;0x72uy;
  0x71uy;0xd2uy;0xc2uy;0x0fuy;0x9buy;0x92uy;0x8fuy;0xe2uy;
  0x27uy;0x0duy;0x6fuy;0xb8uy;0x63uy;0xd5uy;0x17uy;0x38uy;
  0xb4uy;0x8euy;0xeeuy;0xe3uy;0x14uy;0xa7uy;0xccuy;0x8auy;
  0xb9uy;0x32uy;0x16uy;0x45uy;0x48uy;0xe5uy;0x26uy;0xaeuy;
  0x90uy;0x22uy;0x43uy;0x68uy;0x51uy;0x7auy;0xcfuy;0xeauy;
  0xbduy;0x6buy;0xb3uy;0x73uy;0x2buy;0xc0uy;0xe9uy;0xdauy;
  0x99uy;0x83uy;0x2buy;0x61uy;0xcauy;0x01uy;0xb6uy;0xdeuy;
  0x56uy;0x24uy;0x4auy;0x9euy;0x88uy;0xd5uy;0xf9uy;0xb3uy;
  0x79uy;0x73uy;0xf6uy;0x22uy;0xa4uy;0x3duy;0x14uy;0xa6uy;
  0x59uy;0x9buy;0x1fuy;0x65uy;0x4cuy;0xb4uy;0x5auy;0x74uy;
  0xe3uy;0x55uy;0xa5uy
      ]

#reset-options "--initial_fuel 0 --max_fuel 0 --z3rlimit 100"

let test() =
  assert_norm(List.Tot.length k = 32);
  assert_norm(List.Tot.length n = 24);
  assert_norm(List.Tot.length p = 131);
  assert_norm(List.Tot.length bobsk = 32);
  assert_norm(List.Tot.length bobpk = 32);
  assert_norm(List.Tot.length alicesk = 32);
  assert_norm(List.Tot.length alicepk = 32);
  assert_norm(List.Tot.length mac_and_cipher = 147);
    let k:key = createL k in
    let n:nonce = createL n in
    let p:bytes = createL p in
    let bsk:bytes = createL bobsk in
    let bpk:bytes = createL bobpk in
    let ask:bytes = createL alicesk in
    let apk:bytes = createL alicepk in
    let m_c:bytes = createL mac_and_cipher in
    let mac_cipher = cryptobox p n bpk ask in
    let plain = cryptobox_open mac_cipher n apk bsk in
    match plain with
    | None -> false
    | Some plain' ->
      plain' = p &&
      mac_cipher = m_c
