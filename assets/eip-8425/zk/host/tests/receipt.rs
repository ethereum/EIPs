// SPDX-License-Identifier: CC0-1.0

use std::{fs, path::Path};

use eip8425::{journal, verify, PROOF_BYTES, REQUEST_BYTES};

fn example_request() -> [u8; REQUEST_BYTES] {
    let mut request = [0; REQUEST_BYTES];
    hex::decode_to_slice(
        concat!(
            "0000000000000000000000000000000000000000000000000000000000000001", // chain ID
            "9858effd232b4033e47d90003d41ec34ecaeda94",                         // account
            "0000000000000000",                                                 // nonce
            "1111111111111111111111111111111111111111",                         // source
            "bc36789e7a1e281436464229828f817d6612f7b477d66591ff96a9e064bcc98a", // code hash
            "7569b0d2192c429516d9c6a701322c51a72c3f6e8e5c296d0cdc86a85f239fd4", // tag
        ),
        &mut request,
    )
    .unwrap();
    request
}

#[test]
fn public_seed_journal() {
    let output = journal(&example_request());
    assert_eq!(
        hex::encode(&output[..20]),
        "9858effd232b4033e47d90003d41ec34ecaeda94"
    );
    assert_eq!(
        hex::encode(&output[20..52]),
        "7569b0d2192c429516d9c6a701322c51a72c3f6e8e5c296d0cdc86a85f239fd4"
    );
    assert_eq!(
        hex::encode(&output[52..]),
        "252419d58526576f175dce2f379c279d357d335871beb2a2c29f9a46fedb32d8"
    );
}

#[test]
fn rejects_malformed_lengths() {
    let request = example_request();
    for len in [0, PROOF_BYTES - 4, PROOF_BYTES - 1, PROOF_BYTES + 4] {
        assert_eq!(
            verify(&request, &vec![0; len]).unwrap_err().to_string(),
            "invalid seal length"
        );
    }
}

#[test]
#[ignore = "run python3 generate_vector.py in assets/eip-8425 first"]
fn generated_seed_proof() {
    // Cargo runs integration tests from the host crate's directory.
    let vectors = Path::new("../vectors");
    let request = example_request();
    assert_eq!(fs::read(vectors.join("request.bin")).unwrap(), request);
    let proof = fs::read(vectors.join("proof.bin")).unwrap();
    verify(&request, &proof).unwrap();

    for offset in [0, 32, 52, 60, 80, 112] {
        let mut changed = request;
        changed[offset] ^= 1;
        assert!(
            verify(&changed, &proof).is_err(),
            "accepted a change at byte {offset}"
        );
    }
    for offset in [0, 64, 128, 256, proof.len() - 4] {
        let mut corrupted = proof.clone();
        corrupted[offset] ^= 1;
        assert!(
            verify(&request, &corrupted).is_err(),
            "accepted corruption at byte {offset}"
        );
    }
    let mut noncanonical = proof;
    noncanonical[..4].copy_from_slice(&u32::MAX.to_le_bytes());
    assert!(verify(&request, &noncanonical).is_err());
}
