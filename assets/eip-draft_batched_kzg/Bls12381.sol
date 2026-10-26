// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

/// @title Bls12381
/// @notice Thin wrappers around the EIP-2537 BLS12-381 precompiles used for
///         batched KZG proof verification.
/// @dev Encoding (per EIP-2537):
///        - field element: 64 bytes (16 zero bytes || 48-byte big-endian fp)
///        - G1 point:      128 bytes — two field elements (x || y)
///        - G2 point:      256 bytes — two fp2 elements
///        - scalar:        32 bytes  — big-endian
library Bls12381 {
    // ──────────────────────────────────────────────────────────────────────
    //  Precompile addresses (EIP-2537)
    // ──────────────────────────────────────────────────────────────────────

    address internal constant G1ADD_PRECOMPILE = address(0x0B);
    address internal constant G1MSM_PRECOMPILE = address(0x0C);
    address internal constant PAIRING_PRECOMPILE = address(0x0F);

    // ──────────────────────────────────────────────────────────────────────
    //  Sizes
    // ──────────────────────────────────────────────────────────────────────

    uint256 internal constant G1_POINT_SIZE = 128;
    uint256 internal constant G2_POINT_SIZE = 256;
    uint256 internal constant PAIRING_OUTPUT_SIZE = 32;

    // ──────────────────────────────────────────────────────────────────────
    //  Errors
    // ──────────────────────────────────────────────────────────────────────

    error EmptyInput();
    error LengthMismatch();
    error InvalidG1PointLength(uint256 actual);
    error InvalidG2PointLength(uint256 actual);
    error PrecompileCallFailed(address precompile);
    error UnexpectedPrecompileOutput(address precompile);

    // ──────────────────────────────────────────────────────────────────────
    //  Operations
    // ──────────────────────────────────────────────────────────────────────

    /// @notice Add two G1 points: returns a + b.
    /// @dev Calls the BLS12_G1ADD precompile (0x0B). Cheaper than `g1Msm` with
    ///      scalars [1, 1] and reads more clearly when you just need to compose
    ///      two G1 points (e.g., subtraction via add-with-negated-point).
    /// @param a 128-byte G1 point.
    /// @param b 128-byte G1 point.
    /// @return One G1 point (128 bytes) — the sum a + b.
    function g1Add(bytes memory a, bytes memory b) internal view returns (bytes memory) {
        _requireG1Length(a);
        _requireG1Length(b);
        // Fixed 256-byte input — no loop, no allocation tuning needed.
        return _staticcall(G1ADD_PRECOMPILE, abi.encodePacked(a, b), G1_POINT_SIZE);
    }

    /// @notice Multi-scalar multiplication on G1: returns Σ scalars[i] * points[i].
    /// @dev Convenience wrapper that builds the precompile input from parallel
    ///      arrays. Callers that already hold a contiguous [point||scalar] buffer
    ///      should call `g1MsmRaw` directly to skip this packing pass.
    /// @param points  G1 points (128 bytes each).
    /// @param scalars Scalars (32 bytes each); scalars[i] pairs with points[i].
    /// @return One G1 point (128 bytes) — the resulting sum.
    function g1Msm(bytes[] memory points, bytes32[] memory scalars) internal view returns (bytes memory) {
        uint256 n = points.length;
        if (n == 0) revert EmptyInput();
        if (n != scalars.length) revert LengthMismatch();

        // Pre-allocate the final-size buffer (n × 160 bytes) and write each slot
        // directly — O(n) memory traffic, vs. O(n²) for repeated abi.encodePacked.
        uint256 slotSize = G1_POINT_SIZE + 32;
        bytes memory input = new bytes(n * slotSize);

        for (uint256 i; i < n; ++i) {
            bytes memory point = points[i];
            _requireG1Length(point);
            bytes32 scalar = scalars[i];

            // Solidity `bytes memory` layout: word-0 holds the length, payload
            // starts at ptr + 0x20. mcopy (EIP-5656, Cancun) moves the 128-byte
            // point in one opcode; mstore writes the 32-byte scalar. Memory-safe:
            // every write lands inside `input`, free memory pointer untouched.
            assembly ("memory-safe") {
                let dst := add(add(input, 0x20), mul(i, slotSize))
                mcopy(dst, add(point, 0x20), 128) // copy G1 point
                mstore(add(dst, 128), scalar) // append scalar
            }
        }

        return g1MsmRaw(input);
    }

    /// @notice Same as `g1Msm` but takes a pre-built precompile input.
    /// @dev    Skips the per-element copy in `g1Msm` — useful when the caller
    ///         constructs the [point||scalar]*n buffer themselves (e.g., to
    ///         interleave pre-known points with scalars derived in-place).
    /// @param  input Length must be a positive multiple of 160 bytes; each slot
    ///               is [128-byte G1 point || 32-byte scalar]. The precompile
    ///               itself enforces canonical encoding and subgroup membership.
    /// @return One G1 point (128 bytes) — the resulting sum.
    function g1MsmRaw(bytes memory input) internal view returns (bytes memory) {
        if (input.length == 0 || input.length % 160 != 0) revert EmptyInput();
        return _staticcall(G1MSM_PRECOMPILE, input, G1_POINT_SIZE);
    }

    /// @notice Convert a 128-byte EIP-2537 uncompressed G1 point to its 48-byte
    ///         EIP-4844 canonical compressed form.
    /// @dev    Compressed encoding: top 3 bits of byte 0 are flags
    ///           - 0x80 compression (always set)
    ///           - 0x40 infinity (only when input is the point at infinity)
    ///           - 0x20 y-largest (set iff y > (p-1)/2 — picks the canonical y)
    ///         The remaining 5 bits + bytes 1..48 hold x (which fits in 381 bits
    ///         for any canonical input, so the top 3 bits of x are always zero).
    /// @param  uncompressed 128 bytes: [16 zero || 48-byte x || 16 zero || 48-byte y].
    function compress(bytes memory uncompressed) internal pure returns (bytes memory compressed) {
        _requireG1Length(uncompressed);
        compressed = new bytes(48);

        if (_isInfinity(uncompressed)) {
            compressed[0] = 0xc0; // compression | infinity
            return compressed;
        }

        // Copy x bytes (uncompressed[16..64]) into compressed[0..48].
        // mcopy is a single opcode for arbitrary-length memory copy (EIP-5656); the
        // pure-Solidity alternative would be a 48-iteration byte-by-byte loop.
        assembly ("memory-safe") {
            mcopy(add(compressed, 0x20), add(uncompressed, 0x30), 48)
        }

        // Mask the top 3 bits of byte 0 (defensive — always zero for valid x) and OR in flags.
        uint8 flags = 0x80;
        if (_yIsLarger(uncompressed)) flags |= 0x20;
        compressed[0] = bytes1((uint8(compressed[0]) & 0x1F) | flags);
    }

    /// @notice Multi-pairing check: returns true iff Π e(g1Points[i], g2Points[i]) == 1 in GT.
    /// @dev Calls the BLS12_PAIRING_CHECK precompile (0x0F). Output is a 32-byte
    ///      big-endian boolean (1 = paired, 0 = not).
    /// @param g1Points G1 points (128 bytes each).
    /// @param g2Points G2 points (256 bytes each); g2Points[i] pairs with g1Points[i].
    function pairingCheck(bytes[] memory g1Points, bytes[] memory g2Points) internal view returns (bool) {
        uint256 n = g1Points.length;
        if (n == 0) revert EmptyInput();
        if (n != g2Points.length) revert LengthMismatch();

        // Each slot: [128-byte G1 point || 256-byte G2 point] = 384 bytes.
        // See g1Msm above for the rationale behind pre-allocate + mcopy.
        uint256 slotSize = G1_POINT_SIZE + G2_POINT_SIZE;
        bytes memory input = new bytes(n * slotSize);

        for (uint256 i; i < n; ++i) {
            bytes memory g1 = g1Points[i];
            bytes memory g2 = g2Points[i];
            _requireG1Length(g1);
            _requireG2Length(g2);

            // mcopy both points; "memory-safe" — writes stay inside `input`
            // and we don't touch the free memory pointer.
            assembly ("memory-safe") {
                let dst := add(add(input, 0x20), mul(i, slotSize))
                mcopy(dst, add(g1, 0x20), 128)
                mcopy(add(dst, 128), add(g2, 0x20), 256)
            }
        }

        bytes memory output = _staticcall(PAIRING_PRECOMPILE, input, PAIRING_OUTPUT_SIZE);
        return abi.decode(output, (uint256)) == 1;
    }

    // ──────────────────────────────────────────────────────────────────────
    //  Internals
    // ──────────────────────────────────────────────────────────────────────

    /// @dev (p-1)/2 where p is the BLS12-381 base field prime, split into two uint256s.
    // Used by `_yIsLarger` to pick the canonical y in compression.
    uint256 private constant P_HALF_HI = 0x0D0088F51CBFF34D258DD3DB21A5D66B;
    uint256 private constant P_HALF_LO = 0xB23BA5C279C2895FB39869507B587B120F55FFFF58A9FFFFDCFF7FFFFFFFD555;

    function _staticcall(address precompile, bytes memory input, uint256 expectedOutputLength)
        private
        view
        returns (bytes memory output)
    {
        bool ok;
        (ok, output) = precompile.staticcall(input);
        if (!ok) revert PrecompileCallFailed(precompile);
        if (output.length != expectedOutputLength) revert UnexpectedPrecompileOutput(precompile);
    }

    function _requireG1Length(bytes memory point) private pure {
        if (point.length != G1_POINT_SIZE) revert InvalidG1PointLength(point.length);
    }

    function _requireG2Length(bytes memory point) private pure {
        if (point.length != G2_POINT_SIZE) revert InvalidG2PointLength(point.length);
    }

    /// @dev Point-at-infinity in EIP-2537 G1 = 128 zero bytes. OR all 4 words
    ///      together and check for zero in one shot.
    function _isInfinity(bytes memory point) private pure returns (bool isInf) {
        assembly ("memory-safe") {
            // `bytes memory` layout: word 0 holds the length; the 128-byte payload
            // starts at +0x20. The payload is exactly four 32-byte words, so we
            // mload each one, OR them all together, and ask "is the result zero?".
            // If every byte is zero, the OR is zero; otherwise some bit leaks through.
            let chunk0 := mload(add(point, 0x20)) // payload bytes 0..32
            let chunk1 := mload(add(point, 0x40)) // payload bytes 32..64
            let chunk2 := mload(add(point, 0x60)) // payload bytes 64..96
            let chunk3 := mload(add(point, 0x80)) // payload bytes 96..128

            // iszero maps 0 → 1 and any non-zero → 0; Solidity reads that as bool.
            isInf := iszero(or(or(chunk0, chunk1), or(chunk2, chunk3)))
        }
    }

    /// @dev Returns true iff y > (p-1)/2. y lives at bytes 80..128 of the
    ///      uncompressed point (16-byte zero pad + 48-byte fp). We split it
    ///      into a 16-byte high half and a 32-byte low half for the compare.
    function _yIsLarger(bytes memory point) private pure returns (bool) {
        uint256 hi;
        uint256 lo;
        assembly ("memory-safe") {
            hi := shr(128, mload(add(point, 0x70))) // top 16 bytes of y
            lo := mload(add(point, 0x80)) // bottom 32 bytes of y
        }
        return hi > P_HALF_HI || (hi == P_HALF_HI && lo > P_HALF_LO);
    }
}
