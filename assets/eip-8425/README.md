# EIP-8425 recovery proof

Run these commands from `assets/eip-8425`. The [guest](zk/guest/src/main.rs) derives the account and binds the request to its seed. The [verifier](zk/host/src/lib.rs) checks the proof and the [state model](recovery.py) installs the authorized code.

## Build and run fast tests

On a clean checkout these tests check the public journal, recursion parameters, seal length and recovery state transitions. To exercise the full STARK verifier, run the [proof tests](#full-proof-tests).

```sh
cargo +1.96.0 build --release --locked --manifest-path zk/host/Cargo.toml
prover=zk/host/target/release/eip8425
cargo +1.96.0 test --release --locked --manifest-path zk/host/Cargo.toml
python3 -m pip install 'eth-hash[pycryptodome]'
python3 -m unittest discover -p 'test_recovery.py' -v
```

## Build the guest

The [pinned builder](zk/guest/Dockerfile) requires native or emulated Linux/amd64. Check the ELF against the [expected image ID](zk/image-id.hex).

```sh
docker buildx build --platform linux/amd64 \
  --output type=local,dest=zk/guest/elfs zk/guest
elf=zk/guest/elfs/eip8425-seed.elf
test "$("$prover" image-id "$elf")" = "$(cat zk/image-id.hex)"
```

ELF SHA-256 is `aaeadac44d3716d463a5b80f23bf2f645ca68f61d56905c8532642474620e771`. The [outer control ID list](zk/allowed-control-ids.hex) reproduces the [pinned recursion set](https://github.com/risc0/risc0/blob/22c5fb90522cb4d9427d4af6c05e747d20be2b7f/risc0/circuit/recursion/src/control_id.rs#L23-L51). The EIP specifies the [claim encoding](../../EIPS/eip-8425.md#proof-system). RISC Zero documents the [FRI parameters](https://github.com/risc0/risc0/blob/v3.1.0/risc0/zkp/src/lib.rs) and [security assumptions](https://dev.risczero.com/api/3.0/security-model).

## Full proof tests

Install `r0vm` with `rzup install r0vm 3.1.0` and put it on `PATH` or set `RISC0_SERVER_PATH` to its executable. The generator uses the [public test inputs](../../EIPS/eip-8425.md#test-cases) and writes a 144-byte request and a 222,668-byte proof under `zk/vectors/`.

```sh
python3 generate_vector.py &&
"$prover" verify zk/vectors/request.bin zk/vectors/proof.bin &&
cargo +1.96.0 test --release --locked --manifest-path zk/host/Cargo.toml -- --include-ignored &&
python3 -m unittest discover -p 'test_recovery.py' -v
```

The verifier needs only the request and proof. It exits 0 on success, 2 for invalid input and 1 for a local error. Valid proof bytes may differ between runs for the same request.

For another account, use `python3 witness.py --help` for parameters and pipe its private output to `"$prover" prove "$elf" REQUEST_OUT PROOF_OUT`. The helper prompts for the mnemonic and passphrase with echo disabled. Share only the public request and proof.

On an Apple M2 Max, `generate_vector.py` took 24 min 15 s to generate and verify one public test proof with a Rust 1.96.0 release build of the host. The `r0vm` 3.1.0 prover reached 7.24 GiB peak RSS. See the [EIP rationale](../../EIPS/eip-8425.md#rationale) for verification timings.

## Assemble the recovery frame

The example below uses the locally generated test vector. The sponsor checks the chain ID and target, approves payment in an earlier frame and inserts the decoded recovery frame last in the EIP-8141 transaction.

```sh
python3 -m pip install 'rlp==4.1.0'
python3 - <<'PY'
from pathlib import Path
import rlp

request = Path("zk/vectors/request.bin").read_bytes()
proof = Path("zk/vectors/proof.bin").read_bytes()
assert len(request) == 144 and int.from_bytes(request[:32], "big") == 1
target = request[32:52]
assert target.hex() == "9858effd232b4033e47d90003d41ec34ecaeda94"
frame = [7, 0, target, [2_100_000, 183_600], 0, request[52:] + proof]
Path("recover-frame.rlp").write_bytes(rlp.encode(frame))
PY
```
