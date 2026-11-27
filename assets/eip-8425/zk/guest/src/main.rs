// SPDX-License-Identifier: CC0-1.0
#![no_main]

use hmac::{Hmac, Mac};
use k256::elliptic_curve::{sec1::ToEncodedPoint, PrimeField};
use k256::{Scalar, SecretKey};
use risc0_zkvm::guest::env;
use sha2::{Sha256, Sha512};
use sha3::{Digest, Keccak256};

risc0_zkvm::guest::entry!(main);

fn extended_key(key: &[u8], data: &[u8]) -> (Scalar, [u8; 32]) {
    let mut mac = Hmac::<Sha512>::new_from_slice(key).unwrap();
    mac.update(data);
    let output = mac.finalize().into_bytes();
    // BIP-32 rejects IL >= n. A zero IL is permitted for a child tweak.
    let il: [u8; 32] = output[..32].try_into().unwrap();
    let scalar = Option::<Scalar>::from(Scalar::from_repr(il.into())).unwrap();
    (scalar, output[32..].try_into().unwrap())
}

fn derive_account(seed: &[u8], account: u32, change: u32, index: u32) -> [u8; 20] {
    const HARDENED: u32 = 1 << 31;
    assert!(account < HARDENED && change <= 1 && index < HARDENED);

    let (mut scalar, mut chain_code) = extended_key(b"Bitcoin seed", seed);
    assert!(!bool::from(scalar.is_zero()));
    for child in [
        44 | HARDENED,
        60 | HARDENED,
        account | HARDENED,
        change,
        index,
    ] {
        let mut input = [0u8; 37];
        if child & HARDENED != 0 {
            input[1..33].copy_from_slice(&scalar.to_bytes());
        } else {
            let secret = SecretKey::from_bytes(&scalar.to_bytes()).unwrap();
            input[..33].copy_from_slice(secret.public_key().to_encoded_point(true).as_bytes());
        }
        input[33..].copy_from_slice(&child.to_be_bytes());
        let (tweak, next_chain_code) = extended_key(&chain_code, &input);
        scalar += tweak;
        assert!(!bool::from(scalar.is_zero()));
        chain_code = next_chain_code;
    }

    let secret = SecretKey::from_bytes(&scalar.to_bytes()).unwrap();
    let point = secret.public_key().to_encoded_point(false);
    Keccak256::digest(&point.as_bytes()[1..])[12..]
        .try_into()
        .unwrap()
}

fn main() {
    let mut input = [0u8; 168];
    env::read_slice(&mut input);
    let seed = &input[..64];
    let addr = derive_account(
        seed,
        u32::from_be_bytes(input[64..68].try_into().unwrap()),
        u32::from_be_bytes(input[68..72].try_into().unwrap()),
        u32::from_be_bytes(input[72..76].try_into().unwrap()),
    );

    let mut intent = Vec::with_capacity(131);
    intent.extend_from_slice(b"EIP-8425/recover/v1");
    intent.extend_from_slice(&input[76..108]); // chain ID
    intent.extend_from_slice(&addr);
    intent.extend_from_slice(&input[108..]); // nonce, source address, code hash

    let mut mac = Hmac::<Sha256>::new_from_slice(seed).unwrap();
    mac.update(&intent);
    let tag = mac.finalize().into_bytes();
    let digest = Keccak256::new()
        .chain_update(&intent)
        .chain_update(tag)
        .finalize();
    env::commit_slice(&addr);
    env::commit_slice(&tag);
    env::commit_slice(&digest);
}
