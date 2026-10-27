// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Bls12381} from "./Bls12381.sol";

library BlobVerifier {
    // ──────────────────────────────────────────────────────────────────────
    //  Constants
    // ──────────────────────────────────────────────────────────────────────

    /// @dev Address of the EIP-4844 point evaluation precompile.
    address internal constant POINT_EVALUATION_PRECOMPILE = address(0x0A);

    /// @dev Version byte prepended to KZG commitment hashes (EIP-4844 §Helpers).
    bytes1 internal constant VERSIONED_HASH_VERSION_KZG = 0x01;

    /// @dev Byte lengths for KZG G1 points (compressed).
    uint256 internal constant COMMITMENT_LENGTH = 48;
    uint256 internal constant PROOF_LENGTH = 48;

    /// @dev Number of field elements in a blob polynomial (4096).
    ///      First 32 bytes of the expected precompile output.
    // bytes32 internal constant FIELD_ELEMENTS_PER_BLOB = bytes32(uint256(4096));

    /// @dev BLS12-381 scalar field modulus.
    ///      Second 32 bytes of the expected precompile output.
    uint256 internal constant BLS_MODULUS =
        52435875175126190479447740508185965837690552500527637822603658699938581184513;

    // @dev The precompile expected output on success:
    // keccak(FIELD_ELEMENTS_PER_BLOB + BLS_MODULUS)
    bytes32 internal constant POINT_EVALUATION_PRECOMPILE_OUTPUT =
        0xb2157d3a40131b14c4c675335465dffde802f0ce5218ad012284d7f275d1b37c;

    /// @dev BLS12-381 G1 generator in EIP-2537 uncompressed encoding (128 bytes).
    bytes internal constant G1_GENERATOR =
        hex"0000000000000000000000000000000017f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb0000000000000000000000000000000008b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1";

    /// @dev Negated BLS12-381 G2 generator in EIP-2537 uncompressed encoding (256 bytes).
    ///      Used in pairing checks via the identity e(LHS, -G2_gen) · e(RHS, [s]G2) == 1,
    ///      which avoids on-chain G1 negation on the LHS.
    bytes internal constant NEG_G2_GENERATOR =
        hex"00000000000000000000000000000000024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb80000000000000000000000000000000013e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e000000000000000000000000000000000d1b3cc2c7027888be51d9ef691d77bcb679afda66c73f17f9ee3837a55024f78c71363275a75d75d86bab79f74782aa0000000000000000000000000000000013fa4d4a0ad8b1ce186ed5061789213d993923066dddaf1040bc3ff59f825c78df74f2d75467e25e0f55f8a00fa030ed";

    /// @dev Below this opening count the *128 batched verifiers fall back to looping the
    ///      EIP-4844 0x0A precompile on the compressed form. The EIP-2537 batched path's fixed
    ///      overhead (two G1MSMs + one pairing) only pays off above this crossover.
    uint256 internal constant BATCH_THRESHOLD_128 = 5;

    /// @dev Crossover for the general shape (distinct commitments and distinct evaluation points).
    ///      Its LHS MSM has 2n+1 slots instead of n+2, so the batched path pays off one step later.
    uint256 internal constant BATCH_THRESHOLD_GENERAL_128 = 6;

    /// @dev Ethereum mainnet KZG trusted setup point [s]G2 in EIP-2537 uncompressed encoding (256 bytes).
    ///      Decompressed from c-kzg-4844 trusted_setup.txt line 4100 (the second G2 point).
    bytes internal constant KZG_S_G2_MAINNET =
        hex"00000000000000000000000000000000185cbfee53492714734429b7b38608e23926c911cceceac9a36851477ba4c60b087041de621000edc98edada20c1def20000000000000000000000000000000015bfd7dd8cdeb128843bc287230af38926187075cbfbefa81009a2ce615ac53d2914e5870cb452d2afaaab24f3499f7200000000000000000000000000000000014353bdb96b626dd7d5ee8599d1fca2131569490e28de18e82451a496a9c9794ce26d105941f383ee689bfbbb832a99000000000000000000000000000000001666c54b0a32529503432fcae0181b4bef79de09fc63671fda5ed1ba9bfa07899495346f3d7ac9cd23048ef30d0a154f";

    // ──────────────────────────────────────────────────────────────────────
    //  Errors
    // ──────────────────────────────────────────────────────────────────────

    /// @notice The BLOBHASH opcode returned zero for the given index.
    /// @param blobIndex The blob index that was requested.
    error BlobNotFoundAtIndex(uint256 blobIndex);

    /// @param blobHash The blob hash that was requested.
    error BlobHashNotFound(bytes32 blobHash);

    /// @notice The versioned hash has an unexpected version byte.
    /// @param version The version byte found (expected 0x01).
    error InvalidVersionedHashVersion(bytes1 version);

    /// @notice The KZG commitment is not exactly 48 bytes.
    /// @param length The actual length provided.
    error InvalidCommitmentLength(uint256 length);

    /// @notice The point evaluation precompile returned failure.
    ///         This means the proof is invalid: the blob does NOT evaluate
    ///         to the claimed value at the given point.
    error PointEvaluationPrecompileCallFailed();

    /// @notice The KZG proof is not exactly 48 bytes.
    /// @param length The actual length provided.
    error InvalidProofLength(uint256 length);

    error InvalidPointEvaluationPrecompileOutput();

    error ArrayLengthMismatch();

    /// @notice A scalar (z or y) is not less than the BLS12-381 scalar field modulus.
    error InvalidScalar(bytes32 value);

    /// @notice The provided commitment doesn't hash to the claimed blob's versioned hash.
    error CommitmentMismatch(bytes32 expected, bytes32 actual);

    /// @notice The batched pairing check returned 0 (proofs don't verify).
    error PairingCheckFailed();

    // ──────────────────────────────────────────────────────────────────────
    //  Core verifiers — 48-byte (compressed)
    //  EIP-4844 wire format. Each call hits the point-evaluation precompile (0x0A).
    // ──────────────────────────────────────────────────────────────────────

    function verifySinglePoint(uint256 blobIndex, bytes32 z, bytes32 y, bytes calldata commitment, bytes calldata proof)
        internal
        view
    {
        // Retrieve the versioned hash via BLOBHASH opcode
        bytes32 versionedHash = getBlobHash(blobIndex);
        _verifySinglePoint(versionedHash, z, y, commitment, proof);
    }

    function verifySinglePoint(
        bytes32 versionedHash,
        bytes32 z,
        bytes32 y,
        bytes calldata commitment,
        bytes calldata proof
    ) internal view {
        // Check provided hash prefix
        _checkHashPrefix(versionedHash);
        // Retrieve the versioned hash via BLOBHASH opcode
        _verifySinglePoint(versionedHash, z, y, commitment, proof);
    }

    /// @notice Verify multiple blobs at a single (z, y_i) opening, 48-byte (compressed) form.
    /// @dev    Loops the EIP-4844 point-evaluation precompile per blob; compressed inputs
    ///         can't use EIP-2537 batching, so any batched path lives in the `*128` variant.
    function verifySinglePointMultipleBlobs(
        bytes32[] calldata blobHashes,
        bytes32 z,
        bytes32[] calldata y_coordinates,
        bytes[] calldata commitments,
        bytes[] calldata proofs
    ) internal view {
        uint256 blobCount = blobHashes.length;
        if (blobCount != y_coordinates.length || blobCount != commitments.length || blobCount != proofs.length) {
            revert ArrayLengthMismatch();
        }
        for (uint256 i; i < blobCount; ++i) {
            verifySinglePoint(blobHashes[i], z, y_coordinates[i], commitments[i], proofs[i]);
        }
    }

    /// @notice Verify multiple openings of a single blob at the 48-byte (compressed) form.
    /// @dev    Loops the EIP-4844 point-evaluation precompile per (z_i, y_i, π_i); compressed
    ///         inputs can't use EIP-2537 batching, so any batched path lives in the `*128` variant.
    ///         Each opening has its own proof — there is no shared-proof KZG verification scheme
    ///         for distinct evaluation points.
    function verifyMultiplePoints(
        bytes32 blobHash,
        bytes32[] calldata z_coordinates,
        bytes32[] calldata y_coordinates,
        bytes calldata commitment,
        bytes[] calldata proofs
    ) internal view {
        uint256 pointCount = z_coordinates.length;
        if (pointCount != y_coordinates.length || pointCount != proofs.length) revert ArrayLengthMismatch();
        for (uint256 i; i < pointCount; ++i) {
            verifySinglePoint(blobHash, z_coordinates[i], y_coordinates[i], commitment, proofs[i]);
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    //  Core verifiers — 128-byte (uncompressed, EIP-2537 batched)
    //  One amortized pairing check via G1_MSM (0x0C) + PAIRING_CHECK (0x0F).
    // ──────────────────────────────────────────────────────────────────────

    /// @notice Verify multiple openings of a single blob using EIP-2537 batched pairing.
    /// @dev    All G1 points (commitment, proofs) are 128-byte EIP-2537 uncompressed encoding.
    ///         Each opening has its own proof π_i (one per (z_i, y_i) pair).
    ///
    ///         Verification equation, batched with Fiat-Shamir weights r_i:
    ///           e(LHS, -G2_gen) · e(RHS, [s]G2) == 1
    ///         where
    ///           LHS = Σ(r_i·z_i)·π_i + (Σr_i)·C - (Σr_i·y_i)·G1_gen
    ///           RHS = Σr_i·π_i
    function verifyMultiplePoints128(
        bytes32 blobHash,
        bytes32[] calldata z_coordinates,
        bytes32[] calldata y_coordinates,
        bytes calldata commitment,
        bytes[] calldata proofs
    ) internal view {
        uint256 n = z_coordinates.length;
        if (n == 0) revert ArrayLengthMismatch();
        if (n != y_coordinates.length || n != proofs.length) revert ArrayLengthMismatch();

        // Threshold fallback: at small n, looping 0x0A on compressed inputs is
        // cheaper than the EIP-2537 batched pairing. Compress the (single) commitment
        // once and the proofs per iteration; 0x0A validates each opening individually.
        if (n < BATCH_THRESHOLD_128) {
            bytes memory cComp = Bls12381.compress(commitment);
            for (uint256 i; i < n; ++i) {
                if (uint256(z_coordinates[i]) >= BLS_MODULUS) revert InvalidScalar(z_coordinates[i]);
                if (uint256(y_coordinates[i]) >= BLS_MODULUS) revert InvalidScalar(y_coordinates[i]);
                bytes calldata proof = proofs[i];
                if (proof.length != 128) revert InvalidProofLength(proof.length);

                bytes memory pComp = Bls12381.compress(proof);
                _callPointEvaluation(abi.encodePacked(blobHash, z_coordinates[i], y_coordinates[i], cComp, pComp));
            }
            return;
        }

        // 1. Bind the uncompressed commitment to the claimed blobHash by computing
        //    its compressed form, sha256-ing it, and matching against blobHash.
        //    `compress` validates length == 128.
        {
            bytes32 derived = commitmentToVersionedHash(Bls12381.compress(commitment));
            if (derived != blobHash) revert CommitmentMismatch(blobHash, derived);
        }

        // 2. Build LHS and RHS MSM input buffers in one pass.
        //    LHS layout: [(π_i, r_i·z_i) for i in 0..n] || (C, Σr_i) || (G1_gen, -Σr_i·y_i)
        //    RHS layout: [(π_i, r_i)    for i in 0..n]
        //    Each slot is 128-byte point + 32-byte scalar = 160 bytes.
        bytes memory lhsInput = new bytes((n + 2) * 160);
        bytes memory rhsInput = new bytes(n * 160);

        bytes32 seed = _challengeSeed128(blobHash, z_coordinates, y_coordinates, commitment, proofs);

        uint256 rSum;
        uint256 ySum;
        for (uint256 i; i < n; ++i) {
            // Validate scalars in range. The precompile would catch this too, but
            // catching here gives a precise error and avoids unnecessary MSM work.
            if (uint256(z_coordinates[i]) >= BLS_MODULUS) revert InvalidScalar(z_coordinates[i]);
            if (uint256(y_coordinates[i]) >= BLS_MODULUS) revert InvalidScalar(y_coordinates[i]);

            uint256 r = _challengeScalar(seed, i, BLS_MODULUS);
            rSum = addmod(rSum, r, BLS_MODULUS);
            ySum = addmod(ySum, mulmod(r, uint256(y_coordinates[i]), BLS_MODULUS), BLS_MODULUS);

            bytes32 lScalar = bytes32(mulmod(r, uint256(z_coordinates[i]), BLS_MODULUS));
            bytes32 rScalar = bytes32(r);
            bytes calldata proof = proofs[i];
            if (proof.length != 128) revert InvalidProofLength(proof.length);

            // Copy the same proof into both buffers, paired with its respective scalar.
            // Memory-safe: writes stay inside the two pre-allocated buffers.
            assembly ("memory-safe") {
                let lDst := add(add(lhsInput, 0x20), mul(i, 160))
                let rDst := add(add(rhsInput, 0x20), mul(i, 160))
                calldatacopy(lDst, proof.offset, 128)
                mstore(add(lDst, 128), lScalar)
                calldatacopy(rDst, proof.offset, 128)
                mstore(add(rDst, 128), rScalar)
            }
        }

        // 3. Append (C, Σr_i) and (G1_gen, -Σr_i·y_i) at the end of the LHS buffer.
        bytes memory g1Gen = G1_GENERATOR;
        bytes32 commitmentScalar = bytes32(rSum);
        bytes32 g1GenScalar = bytes32(ySum == 0 ? 0 : BLS_MODULUS - ySum); // -ySum mod p
        assembly ("memory-safe") {
            let cDst := add(add(lhsInput, 0x20), mul(n, 160))
            calldatacopy(cDst, commitment.offset, 128)
            mstore(add(cDst, 128), commitmentScalar)

            let gDst := add(add(lhsInput, 0x20), mul(add(n, 1), 160))
            mcopy(gDst, add(g1Gen, 0x20), 128)
            mstore(add(gDst, 128), g1GenScalar)
        }

        // 4. Two MSMs, then the shared pairing tail.
        _pairingCheckOrRevert(Bls12381.g1MsmRaw(lhsInput), Bls12381.g1MsmRaw(rhsInput));
    }

    /// @notice Verify a shared opening point z across multiple blobs using EIP-2537 batched pairing.
    /// @dev    All G1 points (commitments, proofs) are 128-byte EIP-2537 uncompressed encoding.
    ///         Each blob i has its own commitment C_i, proof π_i, and opened value y_i, but
    ///         every blob is opened at the same point z.
    ///
    ///         Verification equation, batched with Fiat-Shamir weights r_i:
    ///           e(LHS, -G2_gen) · e(RHS, [s]G2) == 1
    ///         where
    ///           LHS = Σ r_i·C_i + z·RHS - (Σ r_i·y_i)·G1_gen
    ///           RHS = Σ r_i·π_i
    ///
    ///         The shared z lets us factor it out: Σ(r_i·z)·π_i = z·(Σr_i·π_i) = z·RHS,
    ///         shrinking LHS from 2N+1 to N+2 slots.
    function verifySinglePointMultipleBlobs128(
        bytes32[] calldata blobHashes,
        bytes32 z,
        bytes32[] calldata y_coordinates,
        bytes[] calldata commitments,
        bytes[] calldata proofs
    ) internal view {
        uint256 n = blobHashes.length;
        if (n == 0) revert ArrayLengthMismatch();
        if (n != y_coordinates.length || n != commitments.length || n != proofs.length) {
            revert ArrayLengthMismatch();
        }

        uint256 modulus = uint256(BLS_MODULUS);
        if (uint256(z) >= modulus) revert InvalidScalar(z);

        // Threshold fallback: at small n, looping 0x0A on compressed inputs beats the
        // batched pairing. The 0x0A precompile validates commitment-to-blobHash binding
        // internally, so we skip the explicit binding pass.
        if (n < BATCH_THRESHOLD_128) {
            for (uint256 i; i < n; ++i) {
                if (uint256(y_coordinates[i]) >= modulus) revert InvalidScalar(y_coordinates[i]);
                bytes calldata proof = proofs[i];
                if (proof.length != 128) revert InvalidProofLength(proof.length);

                bytes memory cComp = Bls12381.compress(commitments[i]);
                bytes memory pComp = Bls12381.compress(proof);
                _callPointEvaluation(abi.encodePacked(blobHashes[i], z, y_coordinates[i], cComp, pComp));
            }
            return;
        }

        // Build the two MSM inputs in one pass:
        //   LHS layout: [(C_i, r_i) for i in 0..n]    (slots 0..n)
        //            || (RHS, z)                       (slot n)
        //            || (G1_gen, -Σ r_i·y_i)           (slot n+1)
        //   RHS layout: [(π_i, r_i) for i in 0..n]
        // Each slot is 128-byte point + 32-byte scalar = 160 bytes.
        bytes memory lhsInput = new bytes((n + 2) * 160);
        bytes memory rhsInput = new bytes(n * 160);

        bytes32 seed = _challengeSeed128(blobHashes, z, y_coordinates, commitments, proofs);
        uint256 ySum;

        for (uint256 i; i < n; ++i) {
            // Bind each commitment to its claimed blobHash (also enforces 128-byte length via compress).
            bytes32 derived = commitmentToVersionedHash(Bls12381.compress(commitments[i]));
            if (derived != blobHashes[i]) revert CommitmentMismatch(blobHashes[i], derived);

            if (uint256(y_coordinates[i]) >= modulus) revert InvalidScalar(y_coordinates[i]);

            uint256 r = _challengeScalar(seed, i, modulus);
            ySum = addmod(ySum, mulmod(r, uint256(y_coordinates[i]), modulus), modulus);

            bytes32 rScalar = bytes32(r);
            bytes calldata commitment = commitments[i];
            bytes calldata proof = proofs[i];
            if (proof.length != 128) revert InvalidProofLength(proof.length);

            // LHS commitment slot at i: (C_i, r_i). RHS proof slot at i: (π_i, r_i).
            assembly ("memory-safe") {
                let lDst := add(add(lhsInput, 0x20), mul(i, 160))
                calldatacopy(lDst, commitment.offset, 128)
                mstore(add(lDst, 128), rScalar)

                let rDst := add(add(rhsInput, 0x20), mul(i, 160))
                calldatacopy(rDst, proof.offset, 128)
                mstore(add(rDst, 128), rScalar)
            }
        }

        // Compute RHS first; we'll use its result as a single G1 slot in LHS with scalar z.
        bytes memory rhs = Bls12381.g1MsmRaw(rhsInput);

        // Append (RHS, z) at slot n and (G1_gen, -Σ r_i·y_i) at slot n+1.
        bytes memory g1Gen = G1_GENERATOR;
        bytes32 g1GenScalar = bytes32(ySum == 0 ? 0 : modulus - ySum);
        assembly ("memory-safe") {
            let rhsSlot := add(add(lhsInput, 0x20), mul(n, 160))
            mcopy(rhsSlot, add(rhs, 0x20), 128)
            mstore(add(rhsSlot, 128), z)

            let gSlot := add(add(lhsInput, 0x20), mul(add(n, 1), 160))
            mcopy(gSlot, add(g1Gen, 0x20), 128)
            mstore(add(gSlot, 128), g1GenScalar)
        }

        _pairingCheckOrRevert(Bls12381.g1MsmRaw(lhsInput), rhs);
    }

    /// @notice Verify n openings with distinct commitments AND distinct evaluation points using
    ///         EIP-2537 batched pairing. This is the general shape; the two functions above are
    ///         its factorisations for inputs that share z or share C.
    /// @dev    All G1 points (commitments, proofs) are 128-byte EIP-2537 uncompressed encoding.
    ///         Claim i is (blobHashes[i], commitments[i], z_coordinates[i], y_coordinates[i], proofs[i]).
    ///         Nothing is required to be distinct: a blob may appear more than once, as may a point.
    ///
    ///         Verification equation, batched with Fiat-Shamir weights r_i:
    ///           e(LHS, -G2_gen) · e(RHS, [s]G2) == 1
    ///         where
    ///           LHS = Σ r_i·C_i + Σ (r_i·z_i)·π_i - (Σ r_i·y_i)·G1_gen     (2n+1 slots)
    ///           RHS = Σ r_i·π_i                                             (n slots)
    ///
    ///         This is the shape a rollup hits when each blob is opened at its own challenge point
    ///         (z_i derived from C_i). The LHS cannot be factored, so it costs n-1 more MSM slots
    ///         than the shared-z shape and the crossover sits at BATCH_THRESHOLD_GENERAL_128.
    function verifyMultiplePointsMultipleBlobs128(
        bytes32[] calldata blobHashes,
        bytes32[] calldata z_coordinates,
        bytes32[] calldata y_coordinates,
        bytes[] calldata commitments,
        bytes[] calldata proofs
    ) internal view {
        uint256 n = blobHashes.length;
        if (n == 0) revert ArrayLengthMismatch();
        if (n != z_coordinates.length || n != y_coordinates.length || n != commitments.length || n != proofs.length) {
            revert ArrayLengthMismatch();
        }

        uint256 modulus = BLS_MODULUS;

        // Threshold fallback: loop 0x0A on compressed inputs. 0x0A binds commitment to blobHash
        // and range-checks scalars internally; we pre-check scalars for a uniform error surface.
        if (n < BATCH_THRESHOLD_GENERAL_128) {
            for (uint256 i; i < n; ++i) {
                if (uint256(z_coordinates[i]) >= modulus) revert InvalidScalar(z_coordinates[i]);
                if (uint256(y_coordinates[i]) >= modulus) revert InvalidScalar(y_coordinates[i]);
                bytes calldata proof = proofs[i];
                if (proof.length != 128) revert InvalidProofLength(proof.length);

                bytes memory cComp = Bls12381.compress(commitments[i]);
                bytes memory pComp = Bls12381.compress(proof);
                _callPointEvaluation(abi.encodePacked(blobHashes[i], z_coordinates[i], y_coordinates[i], cComp, pComp));
            }
            return;
        }

        // Build the two MSM inputs in one pass:
        //   LHS layout: [(C_i, r_i)       for i in 0..n]   (slots 0..n-1)
        //            || [(π_i, r_i·z_i)   for i in 0..n]   (slots n..2n-1)
        //            || (G1_gen, -Σ r_i·y_i)               (slot 2n)
        //   RHS layout: [(π_i, r_i)       for i in 0..n]
        // Each slot is 128-byte point + 32-byte scalar = 160 bytes.
        bytes memory lhsInput = new bytes((2 * n + 1) * 160);
        bytes memory rhsInput = new bytes(n * 160);

        bytes32 seed = _challengeSeed128(blobHashes, z_coordinates, y_coordinates, commitments, proofs);
        uint256 ySum;

        for (uint256 i; i < n; ++i) {
            // Bind each commitment to its claimed blobHash (also enforces 128-byte length via compress).
            bytes32 derived = commitmentToVersionedHash(Bls12381.compress(commitments[i]));
            if (derived != blobHashes[i]) revert CommitmentMismatch(blobHashes[i], derived);

            if (uint256(z_coordinates[i]) >= modulus) revert InvalidScalar(z_coordinates[i]);
            if (uint256(y_coordinates[i]) >= modulus) revert InvalidScalar(y_coordinates[i]);

            uint256 r = _challengeScalar(seed, i, modulus);
            ySum = addmod(ySum, mulmod(r, uint256(y_coordinates[i]), modulus), modulus);

            bytes32 rScalar = bytes32(r);
            bytes32 rzScalar = bytes32(mulmod(r, uint256(z_coordinates[i]), modulus));
            bytes calldata commitment = commitments[i];
            bytes calldata proof = proofs[i];
            if (proof.length != 128) revert InvalidProofLength(proof.length);

            // Memory-safe: writes stay inside the two pre-allocated buffers.
            assembly ("memory-safe") {
                // LHS commitment slot i: (C_i, r_i)
                let cDst := add(add(lhsInput, 0x20), mul(i, 160))
                calldatacopy(cDst, commitment.offset, 128)
                mstore(add(cDst, 128), rScalar)

                // LHS proof slot n+i: (π_i, r_i·z_i)
                let pDst := add(add(lhsInput, 0x20), mul(add(n, i), 160))
                calldatacopy(pDst, proof.offset, 128)
                mstore(add(pDst, 128), rzScalar)

                // RHS proof slot i: (π_i, r_i)
                let rDst := add(add(rhsInput, 0x20), mul(i, 160))
                calldatacopy(rDst, proof.offset, 128)
                mstore(add(rDst, 128), rScalar)
            }
        }

        // Append (G1_gen, -Σ r_i·y_i) at slot 2n.
        bytes memory g1Gen = G1_GENERATOR;
        bytes32 g1GenScalar = bytes32(ySum == 0 ? 0 : modulus - ySum);
        assembly ("memory-safe") {
            let gDst := add(add(lhsInput, 0x20), mul(mul(2, n), 160))
            mcopy(gDst, add(g1Gen, 0x20), 128)
            mstore(add(gDst, 128), g1GenScalar)
        }

        // The two MSMs are independent here (no RHS reuse), then the shared pairing tail.
        _pairingCheckOrRevert(Bls12381.g1MsmRaw(lhsInput), Bls12381.g1MsmRaw(rhsInput));
    }

    // ──────────────────────────────────────────────────────────────────────
    //  Internals
    // ──────────────────────────────────────────────────────────────────────

    function _verifySinglePoint(
        bytes32 versionedHash,
        bytes32 z,
        bytes32 y,
        bytes calldata commitment,
        bytes calldata proof
    ) private view {
        if (commitment.length != COMMITMENT_LENGTH) {
            revert InvalidCommitmentLength(commitment.length);
        }
        if (proof.length != PROOF_LENGTH) revert InvalidProofLength(proof.length);
        _callPointEvaluation(abi.encodePacked(versionedHash, z, y, commitment, proof));
    }

    /// @dev Call the EIP-4844 0x0A point-evaluation precompile with a fully-built input.
    ///      Shared by `_verifySinglePoint` (48-byte calldata path) and the *128 threshold
    ///      fallback paths. Each caller builds the input via `abi.encodePacked(...)`,
    ///      sidestepping the calldata-vs-memory mismatch in the function arguments.
    function _callPointEvaluation(bytes memory input) private view {
        (bool ok, bytes memory output) = POINT_EVALUATION_PRECOMPILE.staticcall(input);
        if (!ok) revert PointEvaluationPrecompileCallFailed();
        if (keccak256(output) != POINT_EVALUATION_PRECOMPILE_OUTPUT) revert InvalidPointEvaluationPrecompileOutput();
    }

    /// @dev Final pairing step shared by the *128 batched verifiers:
    ///      e(lhs, -G2_gen) · e(rhs, [s]G2) == 1.
    function _pairingCheckOrRevert(bytes memory lhs, bytes memory rhs) private view {
        bytes[] memory g1Pts = new bytes[](2);
        bytes[] memory g2Pts = new bytes[](2);
        g1Pts[0] = lhs;
        g1Pts[1] = rhs;
        g2Pts[0] = NEG_G2_GENERATOR;
        g2Pts[1] = KZG_S_G2_MAINNET;
        if (!Bls12381.pairingCheck(g1Pts, g2Pts)) revert PairingCheckFailed();
    }

    /// @dev Fiat-Shamir transcript for verifyMultiplePoints128 (one blob, many openings).
    function _challengeSeed128(
        bytes32 blobHash,
        bytes32[] calldata zs,
        bytes32[] calldata ys,
        bytes calldata commitment,
        bytes[] calldata proofs
    ) private pure returns (bytes32) {
        return keccak256(abi.encode("BlobVerifier.verifyMultiplePoints128", blobHash, zs, ys, commitment, proofs));
    }

    /// @dev Fiat-Shamir transcript for verifySinglePointMultipleBlobs128 (many blobs, shared z).
    function _challengeSeed128(
        bytes32[] calldata blobHashes,
        bytes32 z,
        bytes32[] calldata ys,
        bytes[] calldata commitments,
        bytes[] calldata proofs
    ) private pure returns (bytes32) {
        return keccak256(
            abi.encode("BlobVerifier.verifySinglePointMultipleBlobs128", blobHashes, z, ys, commitments, proofs)
        );
    }

    /// @dev Fiat-Shamir transcript for verifyMultiplePointsMultipleBlobs128 (general shape).
    ///      Every prover-controlled input is hashed; the domain string keeps this transcript
    ///      space disjoint from the two factored shapes even where ABI encodings could collide.
    function _challengeSeed128(
        bytes32[] calldata blobHashes,
        bytes32[] calldata zs,
        bytes32[] calldata ys,
        bytes[] calldata commitments,
        bytes[] calldata proofs
    ) private pure returns (bytes32) {
        return keccak256(
            abi.encode("BlobVerifier.verifyMultiplePointsMultipleBlobs128", blobHashes, zs, ys, commitments, proofs)
        );
    }

    /// @dev Per-index challenge scalar in [1, p). Clamps the (astronomically rare)
    ///      zero case to 1 so the random combination stays non-degenerate.
    function _challengeScalar(bytes32 seed, uint256 i, uint256 modulus) private pure returns (uint256 r) {
        r = uint256(keccak256(abi.encode(seed, i))) % modulus;
        if (r == 0) r = 1;
    }

    // ──────────────────────────────────────────────────────────────────────
    //  Utility functions
    // ──────────────────────────────────────────────────────────────────────

    /// @dev Retrieve and validate a blob's versioned hash.
    function getBlobHash(uint256 blobIndex) internal view returns (bytes32 versionedHash) {
        versionedHash = blobhash(blobIndex);

        if (versionedHash == bytes32(0)) {
            revert BlobNotFoundAtIndex(blobIndex);
        }

        _checkHashPrefix(versionedHash);
    }

    /// @notice Compute the versioned hash from a 48-byte (compressed) KZG commitment.
    /// @dev Matches the EIP-4844 spec: version_byte || sha256(commitment)[1:].
    ///      Accepts `bytes memory` so callers holding a freshly-built buffer
    ///      (e.g., the output of `Bls12381.compress`) can pass it directly.
    function commitmentToVersionedHash(bytes memory commitment) internal pure returns (bytes32 versionedHash) {
        if (commitment.length != COMMITMENT_LENGTH) {
            revert InvalidCommitmentLength(commitment.length);
        }
        // EIP-4844: replace the top byte of sha256(commitment) with the KZG version byte (0x01).
        bytes32 digest = sha256(commitment);
        versionedHash = bytes32(
            (uint256(digest) & 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                | (uint256(uint8(VERSIONED_HASH_VERSION_KZG)) << 248)
        );
    }

    /// @notice Find an index of a given blob hash.
    /// @param blobHash is a hash to check.
    /// @return blobIndex if `blobHash` is present among transaction blobs.
    function getBlobIndex(bytes32 blobHash) internal view returns (uint256 blobIndex) {
        while (true) {
            bytes32 blobHashAtIndex = blobhash(blobIndex);
            if (blobHashAtIndex == bytes32(0)) revert BlobHashNotFound(blobHash);
            if (blobHashAtIndex == blobHash) return blobIndex;
            blobIndex++;
        }
    }

    /// @notice Check whether a blob exists at the given index in the current transaction.
    /// @param blobIndex Index to check.
    /// @return exists True if a blob hash is available at this index.
    function blobExists(uint256 blobIndex) internal view returns (bool exists) {
        return blobhash(blobIndex) != bytes32(0);
    }

    /// @notice Count the number of blobs in the current transaction.
    /// @dev Iterates from index 0 until `blobhash` returns zero.
    /// @return count Number of blobs found.
    function getBlobCount() internal view returns (uint256 count) {
        while (true) {
            if (blobhash(count) == bytes32(0)) break;
            count++;
        }
    }

    /// @notice Check that a hash is properly versioned
    function _checkHashPrefix(bytes32 versionedHash) private pure {
        if (versionedHash[0] != VERSIONED_HASH_VERSION_KZG) {
            revert InvalidVersionedHashVersion(versionedHash[0]);
        }
    }
}
