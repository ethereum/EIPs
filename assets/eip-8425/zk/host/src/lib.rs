// SPDX-License-Identifier: CC0-1.0

use anyhow::{ensure, Result};
use hex::FromHex;
use risc0_core::field::baby_bear::{BabyBearElem, P};
use risc0_zkp::{
    core::hash::poseidon2::Poseidon2HashSuite,
    verify::{verify as verify_stark, VerificationError},
};
use risc0_zkvm::{sha::Digest, sha::Digestible, ReceiptClaim, ALLOWED_CONTROL_ROOT};
use sha3::{Digest as _, Keccak256};

pub const REQUEST_BYTES: usize = 144;
pub const PROOF_BYTES: usize = 222_668;
pub const IMAGE_ID: &str = include_str!("../../image-id.hex");
const OUTER_CONTROL_IDS: &str = include_str!("../../allowed-control-ids.hex");
const DOMAIN: &[u8] = b"EIP-8425/recover/v1";

pub fn journal(request: &[u8; REQUEST_BYTES]) -> [u8; 84] {
    let mut hash = Keccak256::new();
    hash.update(DOMAIN);
    hash.update(request);

    let mut journal = [0; 84];
    journal[..20].copy_from_slice(&request[32..52]); // account
    journal[20..52].copy_from_slice(&request[112..144]); // tag
    journal[52..].copy_from_slice(&hash.finalize());
    journal
}

/// Verify a native recursion seal against a locally constructed, unconditional success claim.
pub fn verify(request: &[u8; REQUEST_BYTES], proof: &[u8]) -> Result<()> {
    ensure!(proof.len() == PROOF_BYTES, "invalid seal length");
    let words: Vec<u32> = proof
        .chunks_exact(4)
        .map(|word| u32::from_le_bytes(word.try_into().unwrap()))
        .collect();
    // In the Poseidon2 seal all words are reduced Baby Bear field elements,
    // including the words of Merkle digests. Field elements on the wire are in Montgomery form; the trace-size word is a raw integer.
    ensure!(words.iter().all(|&w| w < P), "noncanonical field element");
    let public_word = |i: usize| BabyBearElem::new_raw(words[i]).as_u32();
    ensure!(words[32] == 18, "unexpected recursion trace size");

    // The recursion circuit outputs the inner control root (8 padded words),
    // followed by the SHA-256 claim digest (16 little-endian halfwords).
    for (i, &expected) in ALLOWED_CONTROL_ROOT.as_words().iter().enumerate() {
        ensure!(
            public_word(2 * i) == expected && public_word(2 * i + 1) == 0,
            "unexpected control root or padding"
        );
    }
    let image_id = Digest::from_hex(IMAGE_ID.trim()).expect("invalid compiled-in image ID");
    let claim = ReceiptClaim::ok(image_id, journal(request).to_vec()).digest();
    for (i, &expected) in claim.as_words().iter().enumerate() {
        ensure!(
            public_word(16 + 2 * i) == expected & 0xffff
                && public_word(17 + 2 * i) == expected >> 16,
            "recovery claim mismatch"
        );
    }

    // The official verifier derives the outer control ID from the seal itself
    // and checks the complete Fiat–Shamir transcript, including end-of-input.
    verify_stark(
        &risc0_circuit_recursion::CIRCUIT,
        &Poseidon2HashSuite::new_suite(),
        &words,
        |_, &control_id| {
            let id = hex::encode(control_id.as_bytes());
            if OUTER_CONTROL_IDS.lines().any(|allowed| allowed == id) {
                Ok(())
            } else {
                Err(VerificationError::ControlVerificationError { control_id })
            }
        },
    )?;
    Ok(())
}

#[test]
fn pinned_recursion_controls() {
    use risc0_zkvm::sha::{Impl, Sha256};

    assert_eq!(
        ALLOWED_CONTROL_ROOT.to_string(),
        "e6feef13db7aed4a731c7b0852de1f5c89b137726073f625d05333184d3a551d"
    );
    let expected_ids = risc0_zkvm::ALLOWED_CONTROL_IDS
        .iter()
        .map(Digest::to_string);
    assert!(OUTER_CONTROL_IDS.lines().eq(expected_ids));
    let bytes = hex::decode(OUTER_CONTROL_IDS.lines().collect::<String>()).unwrap();
    assert_eq!(
        Impl::hash_bytes(&bytes).to_string(),
        "c4f876ad6fbc09316f20dee62e51b33bb98097489b2194738987dd50cc1a5c56"
    );
}
