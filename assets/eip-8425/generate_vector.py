# SPDX-License-Identifier: CC0-1.0
"""Generate the public EIP-8425 test request and proof using the local prover."""

from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory

from witness import encode_witness


def main():
    zk = Path(__file__).resolve().parent / "zk"
    prover = zk / "host/target/release/eip8425"
    elf = zk / "guest/elfs/eip8425-seed.elf"
    vectors = zk / "vectors"
    witness = encode_witness(
        mnemonic=" ".join(["abandon"] * 11 + ["about"]), passphrase="",
        account_index=0, change=0, address_index=0, chain_id=1, nonce=0,
        source=bytes.fromhex("11" * 20),
        code_hash=bytes.fromhex("bc36789e7a1e281436464229828f817d6612f7b477d66591ff96a9e064bcc98a"),
    )
    vectors.mkdir(exist_ok=True)
    with TemporaryDirectory(dir=vectors) as tmp:
        request = Path(tmp) / "request.bin"
        proof = Path(tmp) / "proof.bin"
        subprocess.run([prover, "prove", elf, request, proof], input=witness, check=True)
        # The prover verifies both outputs before publishing this test pair.
        request.replace(vectors / request.name)
        proof.replace(vectors / proof.name)


if __name__ == "__main__":
    main()
