// SPDX-License-Identifier: CC0-1.0

use anyhow::{bail, ensure, Context, Result};
use eip8425::{journal, verify, IMAGE_ID, PROOF_BYTES, REQUEST_BYTES};
use hex::FromHex;
use risc0_zkvm::{compute_image_id, sha::Digest, ExecutorEnv, ExternalProver, Prover, ProverOpts};
use std::{
    env, fs,
    io::{self, Read},
    process::ExitCode,
};

fn read_up_to_sentinel(mut input: impl Read, limit: usize) -> Result<Vec<u8>> {
    let mut bytes = Vec::new();
    input
        .by_ref()
        .take((limit + 1) as u64)
        .read_to_end(&mut bytes)?;
    Ok(bytes)
}

fn prove(elf_path: &str, request_path: &str, proof_path: &str) -> Result<()> {
    let witness = read_up_to_sentinel(io::stdin().lock(), 168)?;
    ensure!(
        witness.len() == 168,
        "expected a 168-byte private witness on stdin"
    );
    let elf = fs::read(elf_path)?;
    let image: Digest = Digest::from_hex(IMAGE_ID.trim())?;
    ensure!(compute_image_id(&elf)? == image, "incorrect guest image");
    let server = env::var_os("RISC0_SERVER_PATH").unwrap_or_else(|| "r0vm".into());
    let prover = ExternalProver::new("local-r0vm", server);
    let env = ExecutorEnv::builder().write_slice(&witness).build()?;
    let result = prover.prove_with_opts(env, &elf, &ProverOpts::succinct().with_dev_mode(false))?;
    result.receipt.verify(image)?;
    let output = &result.receipt.journal.bytes;
    ensure!(output.len() == 84, "unexpected public journal");
    let seal = result.receipt.inner.succinct()?.get_seal_bytes();
    let mut request = [0u8; REQUEST_BYTES];
    request[..32].copy_from_slice(&witness[76..108]); // chain
    request[32..52].copy_from_slice(&output[..20]); // derived account
    request[52..112].copy_from_slice(&witness[108..]); // nonce, source, code hash
    request[112..].copy_from_slice(&output[20..52]); // authorization tag
    ensure!(
        journal(&request).as_slice() == output,
        "request/journal mismatch"
    );
    verify(&request, &seal)?;
    fs::write(request_path, request)?;
    fs::write(proof_path, &seal)?;
    eprintln!(
        "Verified {}-byte STARK seal ({} guest user cycles).",
        seal.len(),
        result.stats.user_cycles
    );
    Ok(())
}

// Reading one extra byte distinguishes oversized inputs without loading the rest.
fn verify_files(request_path: &str, proof_path: &str) -> Result<ExitCode> {
    let request = read_up_to_sentinel(fs::File::open(request_path)?, REQUEST_BYTES)?;
    let proof = read_up_to_sentinel(fs::File::open(proof_path)?, PROOF_BYTES)?;
    let verdict = request
        .as_slice()
        .try_into()
        .context("expected a 144-byte request")
        .and_then(|request| verify(request, &proof));
    match verdict {
        Ok(()) => Ok(ExitCode::SUCCESS),
        Err(error) => {
            eprintln!("Invalid recovery: {error}");
            Ok(ExitCode::from(2))
        }
    }
}

fn main() -> Result<ExitCode> {
    let args: Vec<_> = env::args().skip(1).collect();
    match args.as_slice() {
        [mode, path] if mode == "image-id" => {
            println!("{}", compute_image_id(&fs::read(path)?)?);
            Ok(ExitCode::SUCCESS)
        }
        [mode, elf, request, proof] if mode == "prove" => {
            prove(elf, request, proof)?;
            Ok(ExitCode::SUCCESS)
        }
        [mode, request, proof] if mode == "verify" => verify_files(request, proof),
        _ => bail!("usage: eip8425 image-id ELF | prove ELF REQUEST_OUT PROOF_OUT < WITNESS | verify REQUEST PROOF"),
    }
}
