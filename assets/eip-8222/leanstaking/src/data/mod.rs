use super::{MerklePath, MerkleProof};
use lean_vm::F;

/*
 *                                                  |root|
 *              |node_1|                                                     |node_2|
 * [commitment]           commit([11; 8], [13; 8])       commit([17; 8], [19; 8])  commit([23; 8], [29;8])
 *   ^^^ proving this one
*/
pub fn two_levels_merkle_proof() -> MerkleProof {
    let path = MerklePath {
        // poseidon16(commit(17, 19), commit(23, 29))
        auth_path: vec![[
            F::new(300284318),
            F::new(184251726),
            F::new(785324177),
            F::new(1645200318),
            F::new(218255519),
            F::new(324974344),
            F::new(38180562),
            F::new(1122512566),
        ]],
        // commitment(11, 13)
        leaf_sibling: [
            F::new(1071247239),
            F::new(306727947),
            F::new(1171256860),
            F::new(1640919826),
            F::new(785163668),
            F::new(1285575607),
            F::new(557881172),
            F::new(1283880189),
        ],
        flags: vec![F::new(0)],
        leaf_is_right_child: F::new(0),
    };
    let proof = MerkleProof {
        root: [
            F::new(1214873956),
            F::new(258084305),
            F::new(2002146002),
            F::new(645480002),
            F::new(499722232),
            F::new(67463537),
            F::new(272555026),
            F::new(342163208),
        ],
        path: path,
    };
    return proof;
}

/*
 *                                                  |root|
 *              |node_1|                                                     |node_2|
 * [commitment]           commit([11; 8], [13; 8])       commit([17; 8], [19; 8])  commit([23; 8], [29;8])
 *   ^^^ proving this one
*/
pub fn three_levels_merkle_proof() -> MerkleProof {
    let path = MerklePath {
        // poseidon16(commit(17, 19), commit(23, 29))
        auth_path: vec![
            [
                F::new(300284318),
                F::new(184251726),
                F::new(785324177),
                F::new(1645200318),
                F::new(218255519),
                F::new(324974344),
                F::new(38180562),
                F::new(1122512566),
            ],
            [
                F::new(1214873956),
                F::new(258084305),
                F::new(2002146002),
                F::new(645480002),
                F::new(499722232),
                F::new(67463537),
                F::new(272555026),
                F::new(342163208),
            ],
        ],
        // commitment(11, 13)
        leaf_sibling: [
            F::new(1071247239),
            F::new(306727947),
            F::new(1171256860),
            F::new(1640919826),
            F::new(785163668),
            F::new(1285575607),
            F::new(557881172),
            F::new(1283880189),
        ],
        flags: vec![F::new(0), F::new(0)],
        leaf_is_right_child: F::new(0),
    };
    let proof = MerkleProof {
        root: [
            F::new(834733639),
            F::new(1317596101),
            F::new(525640951),
            F::new(1305261139),
            F::new(763682782),
            F::new(2096546268),
            F::new(278662),
            F::new(548463637),
        ],
        path: path,
    };
    return proof;
}

/// Depth-32 Merkle proof with dummy siblings.
/// leaf_sibling = [5; 8], auth_path sibling[i] = [i+10; 8], all flags = 0.
///
/// To regenerate the root values, feed these same inputs to py/gen_root.py via compile_and_run:
///   public_inputs = nullifier_preimage([2;8]) | validator_key([7;13]) | withdrawal_cred([3;9])
///                   | amount(32) | leaf_sibling([5;8]) | leaf_is_right_child(0)
///                   | for i in 0..32: sibling([i+10;8]) | flag(0)
///   cargo test gen_root_32 -- --nocapture
pub fn depth_32_merkle_proof() -> MerkleProof {
    let mut auth_path = Vec::with_capacity(32);
    for i in 0u32..32 {
        auth_path.push([F::new(i + 10); 8]);
    }
    let path = MerklePath {
        auth_path,
        leaf_sibling: [F::new(5); 8],
        flags: vec![F::new(0); 32],
        leaf_is_right_child: F::new(0),
    };
    MerkleProof {
        root: [
            F::new(319108412),
            F::new(880625412),
            F::new(1057779508),
            F::new(1239166459),
            F::new(493418555),
            F::new(1659687608),
            F::new(898245713),
            F::new(617354080),
        ],
        path,
    }
}
