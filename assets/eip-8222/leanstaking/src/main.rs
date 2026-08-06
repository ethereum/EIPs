use lean_compiler::ProgramSource;
use lean_compiler::try_compile_program;
use lean_prover::default_whir_config;
use lean_prover::prove_execution::prove_execution;
use lean_prover::verify_execution::verify_execution;
use lean_vm::*;

pub mod data;
use crate::data::depth_32_merkle_proof;

pub struct MerklePath {
    pub leaf_sibling: [F; 8],
    pub auth_path: Vec<[F; 8]>,
    pub flags: Vec<F>,
    pub leaf_is_right_child: F,
}

pub struct MerkleProof {
    pub root: [F; 8],
    path: MerklePath,
}

pub struct StakeProof {
    nullifier_preimage: [F; 8],
    validator_key: [F; 13],
    withdrawal_cred: [F; 9],
    nullifier: [F; 8],
    amount: F,
    pub merkle_proof: MerkleProof,
}

impl Into<Vec<F>> for MerkleProof {
    fn into(self) -> Vec<F> {
        assert_eq!(self.path.flags.len(), self.path.auth_path.len());
        let mut res = vec![];
        res.extend_from_slice(&self.path.leaf_sibling);
        res.push(self.path.leaf_is_right_child);
        for (node, flag) in self.path.auth_path.iter().zip(self.path.flags) {
            res.extend_from_slice(node);
            res.push(flag);
        }
        res
    }
}

pub struct StakeProofInputs {
    pub public_inputs: Vec<F>,
    pub private_inputs: Vec<F>,
}

impl Into<StakeProofInputs> for StakeProof {
    fn into(self) -> StakeProofInputs {
        let mut public_inputs = vec![];
        let mut private_inputs = vec![];

        // public inputs
        public_inputs.extend_from_slice(&self.validator_key);
        public_inputs.extend_from_slice(&self.withdrawal_cred);
        public_inputs.push(self.amount);
        public_inputs.extend_from_slice(&self.nullifier);
        public_inputs.extend_from_slice(&self.merkle_proof.root);

        // private inputs
        private_inputs.extend_from_slice(&self.nullifier_preimage);
        let merkle_proof: Vec<F> = self.merkle_proof.into();
        private_inputs.extend_from_slice(&merkle_proof);

        StakeProofInputs {
            public_inputs,
            private_inputs,
        }
    }
}

const N_SAMPLES: u16 = 500;

fn main() {
    let path = format!("{}/py/stake.py", env!("CARGO_MANIFEST_DIR"));
    let lean_pg = &ProgramSource::Filepath(path);
    let merkle_proof = depth_32_merkle_proof();
    let nullifier = [
        F::new(1943526546),
        F::new(660031786),
        F::new(925555113),
        F::new(1029853471),
        F::new(791673069),
        F::new(822174872),
        F::new(578818453),
        F::new(1335880560),
    ];
    let stake_proof = StakeProof {
        nullifier_preimage: [F::new(2); 8],
        validator_key: [F::new(7); 13],
        withdrawal_cred: [F::new(3); 9],
        amount: F::new(32),
        merkle_proof,
        nullifier,
    };
    let stake_proof_inputs: StakeProofInputs = stake_proof.into();

    let bytecode = try_compile_program(lean_pg).unwrap();
    let witness = ExecutionWitness {
        private_input: stake_proof_inputs.private_inputs.as_slice(),
        ..ExecutionWitness::empty()
    };

    for rho in [1, 2, 3, 4] {
        let whir_config = default_whir_config(rho);
        let mut total_proof_time = std::time::Duration::ZERO;
        let mut total_verification_time = std::time::Duration::ZERO;
        let mut proof_size_fe = 0;

        for _ in 0..N_SAMPLES {
            let time = std::time::Instant::now();
            let proof = prove_execution(
                &bytecode,
                &stake_proof_inputs.public_inputs,
                &witness,
                &whir_config,
                false,
            );
            total_proof_time += time.elapsed();

            let time = std::time::Instant::now();
            verify_execution(
                &bytecode,
                &stake_proof_inputs.public_inputs,
                proof.proof.clone(),
            )
            .unwrap();
            total_verification_time += time.elapsed();

            proof_size_fe = proof.proof.proof_size_fe();
        }

        let div: f32 = N_SAMPLES.into();
        println!(
            "Rho: {}, avg proving time: {:.3}s, avg verification time: {:.3}s, proof size: {} (~{} KB)",
            rho,
            total_proof_time.as_secs_f32() / div,
            total_verification_time.as_secs_f32() / div,
            proof_size_fe,
            proof_size_fe * 31 / 8 / 1024
        );
    }
}

#[cfg(test)]
pub mod tests {

    use lean_compiler::*;
    use lean_vm::*;

    #[test]
    pub fn test_commit() {
        let path = format!("{}/py/commit.py", env!("CARGO_MANIFEST_DIR"));
        let lean_pg = &ProgramSource::Filepath(path);
        let nullifier_preimage = [F::new(23); 8];
        let validator_key = [F::new(29); 13];
        let withdrawal_cred = [F::new(31); 9];
        let amount = [F::new(32)];
        let inputs = [
            nullifier_preimage.as_slice(),
            validator_key.as_slice(),
            withdrawal_cred.as_slice(),
            amount.as_slice(),
        ]
        .concat();
        compile_and_run(lean_pg, (&inputs, &[]), false);
    }

    #[test]
    pub fn test_hash() {
        let a = [F::new(11); 8];
        let b = [F::new(13); 8];
        let path = format!("{}/py/hash.py", env!("CARGO_MANIFEST_DIR"));
        let lean_pg = &ProgramSource::Filepath(path);
        let a_b = [a, b].concat();
        compile_and_run(lean_pg, (&a_b, &[]), false);
    }

    #[test]
    pub fn gen_root_32() {
        let path = format!("{}/py/gen_root.py", env!("CARGO_MANIFEST_DIR"));
        let lean_pg = &ProgramSource::Filepath(path);

        // Same inputs as main(): nullifier_preimage=2, validator_key=7, withdrawal_cred=3, amount=32
        let nullifier_preimage = [F::new(2); 8];
        let validator_key = [F::new(7); 13];
        let withdrawal_cred = [F::new(3); 9];
        let amount = [F::new(32)];

        // leaf_sibling and leaf_is_right_child
        let leaf_sibling = [F::new(5); 8];
        let leaf_is_right_child = [F::new(0)];

        // 32 levels: each has sibling(8) + flag(1)
        let mut level_data: Vec<F> = Vec::new();
        for i in 0u32..32 {
            level_data.extend_from_slice(&[F::new(i + 10); 8]); // sibling
            level_data.push(F::new(0)); // flag (always left child)
        }

        let inputs = [
            nullifier_preimage.as_slice(),
            validator_key.as_slice(),
            withdrawal_cred.as_slice(),
            amount.as_slice(),
            leaf_sibling.as_slice(),
            leaf_is_right_child.as_slice(),
            level_data.as_slice(),
        ]
        .concat();

        compile_and_run(lean_pg, (&inputs, &[]), false);
    }
}
