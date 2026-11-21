// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

/// @title LeanXmss
/// @notice Verifier for leanXMSS: two layers of height-16 XMSS over WOTS+C one-time keys
///         (58 chains of 4 positions, target sum 106), on Keccak-256 truncated to 16 bytes.
/// @dev This file is generated: edit `scripts/LeanXmss.sol.template` and run
///      `scripts/generate-verifier.py`. `test/helpers/LeanXmssReference.sol` is the same
///      verifier written with loops, which is easier to read against the spec.
///      The spec is `EthLib/Cryptography/Xmss` in ethereum/EthLib; `xmss/README.md` has the
///      commit followed here.
///      Public key: root (16) ‖ public parameter P (16). Signature: leaf index (u32 LE) ‖ bottom
///      layer ‖ top layer, each randomizer (16) ‖ 58 chain values (928) ‖ 16 siblings (256).
///      172 KECCAK256 calls.
library LeanXmss {
    uint256 internal constant SIGNATURE_LENGTH = 2404;

    /// @notice The leaf index `signature` carries: its first four bytes, little-endian. It does
    ///         not verify the signature. Reverts for a signature of the wrong length.
    function signatureIndex(bytes calldata signature) internal pure returns (uint32 index) {
        if (signature.length != SIGNATURE_LENGTH) revert();
        assembly ("memory-safe") {
            let le := shr(224, calldataload(signature.offset))
            index := or(
                or(shl(24, and(le, 0xff)), shl(8, and(le, 0xff00))),
                or(and(shr(8, le), 0xff00), shr(24, le))
            )
        }
    }

    /// @notice Verify `signature` over `message` against `publicKey`, at the leaf index the
    ///         signature carries. False for a signature of the wrong length.
    /// @dev The hashes are 7.6k of its gas, so the code is written to do little else: the chains
    ///      and the path levels are unrolled, and it works at fixed memory addresses.
    function verify(bytes32 publicKey, bytes32 message, bytes calldata signature)
        internal
        pure
        returns (bool ok)
    {
        if (signature.length != SIGNATURE_LENGTH) return false;
        assembly {
            // A hash input starts with the word `P | A`: the public parameter, then the address
            // `[lo:4 | hi:3 | t + 32 step:1 | zero:8]`, the fields little-endian. In that word,
            // `lo` sits at bit 96, the level (the low byte of `hi`) at bit 88, the top layer's
            // flag (bit 23 of `hi`) at bit 79, the type at bit 64 and the step at bit 69. A hash
            // value is 16 bytes, kept in the high half of a word.
            //
            // Memory, with every offset a constant:
            //   0      X: the input of a chain step that leaves position 2. Also the digest's
            //          input, and a path node's at an odd level.
            //   0x80   Y: the input of a step that leaves position 1, and a path node's at an
            //          even level.
            //   0xd0   Z: the input of a step that leaves position 0.
            //   0x120  The leaf's input: its address word, then the 58 chain ends from 0x140.
            //   0x140  The layer being verified, copied from the signature: the randomizer, the
            //          chain values from 0x150 and the siblings from 0x4f0, up to 0x5f0.
            // Fixed addresses aren't memory-safe as Solidity defines it, so the block isn't marked
            // as such. It saves what the caller allocated from 0x80 and puts it back, with the free
            // memory pointer, which the hash inputs at 0 run over.
            //
            // MSTORE writes a hash value with the 16 bytes that follow it in its word, and the
            // layout is chosen so that those land where they don't matter:
            // - A step's input is `P | A`, the value and the chain index. The step's address only
            //   depends on the layer and on the position, hence one buffer per position, whose
            //   `P | A` is written once per layer. A step writes the value and then the index
            //   over what came with the value.
            // - A chain's end goes 16 bytes below where its value was, and the chains are done in
            //   order. What comes with an end then lands on the value that chain just read, and
            //   the leaf's input ends up where the layer was, without a copy.
            // - A path node is hashed from one buffer into the other, so its two children can be
            //   written in either order.

            /// Whether the digest, in the low half of `digits`, is a codeword. As a little-endian
            /// integer its two-bit digits past the 58th are zero, which are the high half of its
            /// 15th byte and its 16th, and the others sum to 106. The digits are summed in pairs,
            /// then per byte, then the bytes by a product. No sum depends on the byte order.
            function isCodeword(digits) -> r {
                if iszero(and(digits, 0xf0ff)) {
                    let x :=
                        add(
                            and(digits, 0x33333333333333333333333333333333),
                            and(shr(2, digits), 0x33333333333333333333333333333333)
                        )
                    x := add(
                        and(x, 0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f),
                        and(shr(4, x), 0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f)
                    )
                    r := eq(byte(16, mul(x, 0x01010101010101010101010101010101)), 106)
                }
            }

            /// Writes the 58 chain ends of the layer at 0x140 over it, from 0x140. `digits` is
            /// the digest as the big-endian number its bytes read as, so chain `i` has its digit
            /// in byte `i / 4`, which is at bit `120 - 8 * (i / 4)`, shifted by `2 * (i % 4)`.
            ///
            /// A chain starts at its digit and ends at position 3, so it takes 3 minus the digit
            /// steps. The tests go from the most frequent digit to the least: 3, then 2, then 1
            /// or 0, and a chain falls through the steps it has left.
            function chainEnds(digits) {
                // A bit is set where the digit under it is 3.
                let threes := and(digits, shr(1, digits))
                // Chain 0.
                {
                    let v := mload(0x150)
                    if iszero(and(threes, 0x01000000000000000000000000000000)) {
                        if iszero(and(digits, 0x02000000000000000000000000000000)) {
                            if iszero(and(digits, 0x01000000000000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, 0)
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, 0)
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, 0)
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x140, v)
                }
                // Chain 1.
                {
                    let v := mload(0x160)
                    if iszero(and(threes, 0x04000000000000000000000000000000)) {
                        if iszero(and(digits, 0x08000000000000000000000000000000)) {
                            if iszero(and(digits, 0x04000000000000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 1))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 1))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 1))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x150, v)
                }
                // Chain 2.
                {
                    let v := mload(0x170)
                    if iszero(and(threes, 0x10000000000000000000000000000000)) {
                        if iszero(and(digits, 0x20000000000000000000000000000000)) {
                            if iszero(and(digits, 0x10000000000000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 2))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 2))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 2))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x160, v)
                }
                // Chain 3.
                {
                    let v := mload(0x180)
                    if iszero(and(threes, 0x40000000000000000000000000000000)) {
                        if iszero(and(digits, 0x80000000000000000000000000000000)) {
                            if iszero(and(digits, 0x40000000000000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 3))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 3))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 3))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x170, v)
                }
                // Chain 4.
                {
                    let v := mload(0x190)
                    if iszero(and(threes, 0x00010000000000000000000000000000)) {
                        if iszero(and(digits, 0x00020000000000000000000000000000)) {
                            if iszero(and(digits, 0x00010000000000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 4))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 4))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 4))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x180, v)
                }
                // Chain 5.
                {
                    let v := mload(0x1a0)
                    if iszero(and(threes, 0x00040000000000000000000000000000)) {
                        if iszero(and(digits, 0x00080000000000000000000000000000)) {
                            if iszero(and(digits, 0x00040000000000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 5))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 5))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 5))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x190, v)
                }
                // Chain 6.
                {
                    let v := mload(0x1b0)
                    if iszero(and(threes, 0x00100000000000000000000000000000)) {
                        if iszero(and(digits, 0x00200000000000000000000000000000)) {
                            if iszero(and(digits, 0x00100000000000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 6))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 6))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 6))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x1a0, v)
                }
                // Chain 7.
                {
                    let v := mload(0x1c0)
                    if iszero(and(threes, 0x00400000000000000000000000000000)) {
                        if iszero(and(digits, 0x00800000000000000000000000000000)) {
                            if iszero(and(digits, 0x00400000000000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 7))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 7))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 7))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x1b0, v)
                }
                // Chain 8.
                {
                    let v := mload(0x1d0)
                    if iszero(and(threes, 0x00000100000000000000000000000000)) {
                        if iszero(and(digits, 0x00000200000000000000000000000000)) {
                            if iszero(and(digits, 0x00000100000000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 8))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 8))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 8))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x1c0, v)
                }
                // Chain 9.
                {
                    let v := mload(0x1e0)
                    if iszero(and(threes, 0x00000400000000000000000000000000)) {
                        if iszero(and(digits, 0x00000800000000000000000000000000)) {
                            if iszero(and(digits, 0x00000400000000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 9))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 9))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 9))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x1d0, v)
                }
                // Chain 10.
                {
                    let v := mload(0x1f0)
                    if iszero(and(threes, 0x00001000000000000000000000000000)) {
                        if iszero(and(digits, 0x00002000000000000000000000000000)) {
                            if iszero(and(digits, 0x00001000000000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 10))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 10))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 10))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x1e0, v)
                }
                // Chain 11.
                {
                    let v := mload(0x200)
                    if iszero(and(threes, 0x00004000000000000000000000000000)) {
                        if iszero(and(digits, 0x00008000000000000000000000000000)) {
                            if iszero(and(digits, 0x00004000000000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 11))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 11))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 11))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x1f0, v)
                }
                // Chain 12.
                {
                    let v := mload(0x210)
                    if iszero(and(threes, 0x00000001000000000000000000000000)) {
                        if iszero(and(digits, 0x00000002000000000000000000000000)) {
                            if iszero(and(digits, 0x00000001000000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 12))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 12))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 12))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x200, v)
                }
                // Chain 13.
                {
                    let v := mload(0x220)
                    if iszero(and(threes, 0x00000004000000000000000000000000)) {
                        if iszero(and(digits, 0x00000008000000000000000000000000)) {
                            if iszero(and(digits, 0x00000004000000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 13))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 13))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 13))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x210, v)
                }
                // Chain 14.
                {
                    let v := mload(0x230)
                    if iszero(and(threes, 0x00000010000000000000000000000000)) {
                        if iszero(and(digits, 0x00000020000000000000000000000000)) {
                            if iszero(and(digits, 0x00000010000000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 14))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 14))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 14))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x220, v)
                }
                // Chain 15.
                {
                    let v := mload(0x240)
                    if iszero(and(threes, 0x00000040000000000000000000000000)) {
                        if iszero(and(digits, 0x00000080000000000000000000000000)) {
                            if iszero(and(digits, 0x00000040000000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 15))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 15))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 15))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x230, v)
                }
                // Chain 16.
                {
                    let v := mload(0x250)
                    if iszero(and(threes, 0x00000000010000000000000000000000)) {
                        if iszero(and(digits, 0x00000000020000000000000000000000)) {
                            if iszero(and(digits, 0x00000000010000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 16))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 16))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 16))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x240, v)
                }
                // Chain 17.
                {
                    let v := mload(0x260)
                    if iszero(and(threes, 0x00000000040000000000000000000000)) {
                        if iszero(and(digits, 0x00000000080000000000000000000000)) {
                            if iszero(and(digits, 0x00000000040000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 17))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 17))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 17))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x250, v)
                }
                // Chain 18.
                {
                    let v := mload(0x270)
                    if iszero(and(threes, 0x00000000100000000000000000000000)) {
                        if iszero(and(digits, 0x00000000200000000000000000000000)) {
                            if iszero(and(digits, 0x00000000100000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 18))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 18))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 18))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x260, v)
                }
                // Chain 19.
                {
                    let v := mload(0x280)
                    if iszero(and(threes, 0x00000000400000000000000000000000)) {
                        if iszero(and(digits, 0x00000000800000000000000000000000)) {
                            if iszero(and(digits, 0x00000000400000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 19))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 19))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 19))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x270, v)
                }
                // Chain 20.
                {
                    let v := mload(0x290)
                    if iszero(and(threes, 0x00000000000100000000000000000000)) {
                        if iszero(and(digits, 0x00000000000200000000000000000000)) {
                            if iszero(and(digits, 0x00000000000100000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 20))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 20))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 20))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x280, v)
                }
                // Chain 21.
                {
                    let v := mload(0x2a0)
                    if iszero(and(threes, 0x00000000000400000000000000000000)) {
                        if iszero(and(digits, 0x00000000000800000000000000000000)) {
                            if iszero(and(digits, 0x00000000000400000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 21))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 21))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 21))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x290, v)
                }
                // Chain 22.
                {
                    let v := mload(0x2b0)
                    if iszero(and(threes, 0x00000000001000000000000000000000)) {
                        if iszero(and(digits, 0x00000000002000000000000000000000)) {
                            if iszero(and(digits, 0x00000000001000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 22))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 22))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 22))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x2a0, v)
                }
                // Chain 23.
                {
                    let v := mload(0x2c0)
                    if iszero(and(threes, 0x00000000004000000000000000000000)) {
                        if iszero(and(digits, 0x00000000008000000000000000000000)) {
                            if iszero(and(digits, 0x00000000004000000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 23))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 23))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 23))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x2b0, v)
                }
                // Chain 24.
                {
                    let v := mload(0x2d0)
                    if iszero(and(threes, 0x00000000000001000000000000000000)) {
                        if iszero(and(digits, 0x00000000000002000000000000000000)) {
                            if iszero(and(digits, 0x00000000000001000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 24))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 24))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 24))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x2c0, v)
                }
                // Chain 25.
                {
                    let v := mload(0x2e0)
                    if iszero(and(threes, 0x00000000000004000000000000000000)) {
                        if iszero(and(digits, 0x00000000000008000000000000000000)) {
                            if iszero(and(digits, 0x00000000000004000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 25))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 25))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 25))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x2d0, v)
                }
                // Chain 26.
                {
                    let v := mload(0x2f0)
                    if iszero(and(threes, 0x00000000000010000000000000000000)) {
                        if iszero(and(digits, 0x00000000000020000000000000000000)) {
                            if iszero(and(digits, 0x00000000000010000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 26))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 26))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 26))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x2e0, v)
                }
                // Chain 27.
                {
                    let v := mload(0x300)
                    if iszero(and(threes, 0x00000000000040000000000000000000)) {
                        if iszero(and(digits, 0x00000000000080000000000000000000)) {
                            if iszero(and(digits, 0x00000000000040000000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 27))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 27))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 27))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x2f0, v)
                }
                // Chain 28.
                {
                    let v := mload(0x310)
                    if iszero(and(threes, 0x00000000000000010000000000000000)) {
                        if iszero(and(digits, 0x00000000000000020000000000000000)) {
                            if iszero(and(digits, 0x00000000000000010000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 28))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 28))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 28))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x300, v)
                }
                // Chain 29.
                {
                    let v := mload(0x320)
                    if iszero(and(threes, 0x00000000000000040000000000000000)) {
                        if iszero(and(digits, 0x00000000000000080000000000000000)) {
                            if iszero(and(digits, 0x00000000000000040000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 29))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 29))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 29))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x310, v)
                }
                // Chain 30.
                {
                    let v := mload(0x330)
                    if iszero(and(threes, 0x00000000000000100000000000000000)) {
                        if iszero(and(digits, 0x00000000000000200000000000000000)) {
                            if iszero(and(digits, 0x00000000000000100000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 30))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 30))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 30))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x320, v)
                }
                // Chain 31.
                {
                    let v := mload(0x340)
                    if iszero(and(threes, 0x00000000000000400000000000000000)) {
                        if iszero(and(digits, 0x00000000000000800000000000000000)) {
                            if iszero(and(digits, 0x00000000000000400000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 31))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 31))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 31))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x330, v)
                }
                // Chain 32.
                {
                    let v := mload(0x350)
                    if iszero(and(threes, 0x00000000000000000100000000000000)) {
                        if iszero(and(digits, 0x00000000000000000200000000000000)) {
                            if iszero(and(digits, 0x00000000000000000100000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 32))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 32))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 32))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x340, v)
                }
                // Chain 33.
                {
                    let v := mload(0x360)
                    if iszero(and(threes, 0x00000000000000000400000000000000)) {
                        if iszero(and(digits, 0x00000000000000000800000000000000)) {
                            if iszero(and(digits, 0x00000000000000000400000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 33))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 33))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 33))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x350, v)
                }
                // Chain 34.
                {
                    let v := mload(0x370)
                    if iszero(and(threes, 0x00000000000000001000000000000000)) {
                        if iszero(and(digits, 0x00000000000000002000000000000000)) {
                            if iszero(and(digits, 0x00000000000000001000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 34))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 34))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 34))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x360, v)
                }
                // Chain 35.
                {
                    let v := mload(0x380)
                    if iszero(and(threes, 0x00000000000000004000000000000000)) {
                        if iszero(and(digits, 0x00000000000000008000000000000000)) {
                            if iszero(and(digits, 0x00000000000000004000000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 35))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 35))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 35))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x370, v)
                }
                // Chain 36.
                {
                    let v := mload(0x390)
                    if iszero(and(threes, 0x00000000000000000001000000000000)) {
                        if iszero(and(digits, 0x00000000000000000002000000000000)) {
                            if iszero(and(digits, 0x00000000000000000001000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 36))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 36))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 36))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x380, v)
                }
                // Chain 37.
                {
                    let v := mload(0x3a0)
                    if iszero(and(threes, 0x00000000000000000004000000000000)) {
                        if iszero(and(digits, 0x00000000000000000008000000000000)) {
                            if iszero(and(digits, 0x00000000000000000004000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 37))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 37))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 37))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x390, v)
                }
                // Chain 38.
                {
                    let v := mload(0x3b0)
                    if iszero(and(threes, 0x00000000000000000010000000000000)) {
                        if iszero(and(digits, 0x00000000000000000020000000000000)) {
                            if iszero(and(digits, 0x00000000000000000010000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 38))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 38))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 38))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x3a0, v)
                }
                // Chain 39.
                {
                    let v := mload(0x3c0)
                    if iszero(and(threes, 0x00000000000000000040000000000000)) {
                        if iszero(and(digits, 0x00000000000000000080000000000000)) {
                            if iszero(and(digits, 0x00000000000000000040000000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 39))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 39))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 39))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x3b0, v)
                }
                // Chain 40.
                {
                    let v := mload(0x3d0)
                    if iszero(and(threes, 0x00000000000000000000010000000000)) {
                        if iszero(and(digits, 0x00000000000000000000020000000000)) {
                            if iszero(and(digits, 0x00000000000000000000010000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 40))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 40))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 40))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x3c0, v)
                }
                // Chain 41.
                {
                    let v := mload(0x3e0)
                    if iszero(and(threes, 0x00000000000000000000040000000000)) {
                        if iszero(and(digits, 0x00000000000000000000080000000000)) {
                            if iszero(and(digits, 0x00000000000000000000040000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 41))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 41))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 41))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x3d0, v)
                }
                // Chain 42.
                {
                    let v := mload(0x3f0)
                    if iszero(and(threes, 0x00000000000000000000100000000000)) {
                        if iszero(and(digits, 0x00000000000000000000200000000000)) {
                            if iszero(and(digits, 0x00000000000000000000100000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 42))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 42))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 42))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x3e0, v)
                }
                // Chain 43.
                {
                    let v := mload(0x400)
                    if iszero(and(threes, 0x00000000000000000000400000000000)) {
                        if iszero(and(digits, 0x00000000000000000000800000000000)) {
                            if iszero(and(digits, 0x00000000000000000000400000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 43))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 43))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 43))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x3f0, v)
                }
                // Chain 44.
                {
                    let v := mload(0x410)
                    if iszero(and(threes, 0x00000000000000000000000100000000)) {
                        if iszero(and(digits, 0x00000000000000000000000200000000)) {
                            if iszero(and(digits, 0x00000000000000000000000100000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 44))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 44))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 44))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x400, v)
                }
                // Chain 45.
                {
                    let v := mload(0x420)
                    if iszero(and(threes, 0x00000000000000000000000400000000)) {
                        if iszero(and(digits, 0x00000000000000000000000800000000)) {
                            if iszero(and(digits, 0x00000000000000000000000400000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 45))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 45))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 45))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x410, v)
                }
                // Chain 46.
                {
                    let v := mload(0x430)
                    if iszero(and(threes, 0x00000000000000000000001000000000)) {
                        if iszero(and(digits, 0x00000000000000000000002000000000)) {
                            if iszero(and(digits, 0x00000000000000000000001000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 46))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 46))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 46))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x420, v)
                }
                // Chain 47.
                {
                    let v := mload(0x440)
                    if iszero(and(threes, 0x00000000000000000000004000000000)) {
                        if iszero(and(digits, 0x00000000000000000000008000000000)) {
                            if iszero(and(digits, 0x00000000000000000000004000000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 47))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 47))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 47))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x430, v)
                }
                // Chain 48.
                {
                    let v := mload(0x450)
                    if iszero(and(threes, 0x00000000000000000000000001000000)) {
                        if iszero(and(digits, 0x00000000000000000000000002000000)) {
                            if iszero(and(digits, 0x00000000000000000000000001000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 48))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 48))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 48))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x440, v)
                }
                // Chain 49.
                {
                    let v := mload(0x460)
                    if iszero(and(threes, 0x00000000000000000000000004000000)) {
                        if iszero(and(digits, 0x00000000000000000000000008000000)) {
                            if iszero(and(digits, 0x00000000000000000000000004000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 49))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 49))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 49))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x450, v)
                }
                // Chain 50.
                {
                    let v := mload(0x470)
                    if iszero(and(threes, 0x00000000000000000000000010000000)) {
                        if iszero(and(digits, 0x00000000000000000000000020000000)) {
                            if iszero(and(digits, 0x00000000000000000000000010000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 50))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 50))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 50))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x460, v)
                }
                // Chain 51.
                {
                    let v := mload(0x480)
                    if iszero(and(threes, 0x00000000000000000000000040000000)) {
                        if iszero(and(digits, 0x00000000000000000000000080000000)) {
                            if iszero(and(digits, 0x00000000000000000000000040000000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 51))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 51))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 51))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x470, v)
                }
                // Chain 52.
                {
                    let v := mload(0x490)
                    if iszero(and(threes, 0x00000000000000000000000000010000)) {
                        if iszero(and(digits, 0x00000000000000000000000000020000)) {
                            if iszero(and(digits, 0x00000000000000000000000000010000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 52))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 52))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 52))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x480, v)
                }
                // Chain 53.
                {
                    let v := mload(0x4a0)
                    if iszero(and(threes, 0x00000000000000000000000000040000)) {
                        if iszero(and(digits, 0x00000000000000000000000000080000)) {
                            if iszero(and(digits, 0x00000000000000000000000000040000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 53))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 53))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 53))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x490, v)
                }
                // Chain 54.
                {
                    let v := mload(0x4b0)
                    if iszero(and(threes, 0x00000000000000000000000000100000)) {
                        if iszero(and(digits, 0x00000000000000000000000000200000)) {
                            if iszero(and(digits, 0x00000000000000000000000000100000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 54))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 54))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 54))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x4a0, v)
                }
                // Chain 55.
                {
                    let v := mload(0x4c0)
                    if iszero(and(threes, 0x00000000000000000000000000400000)) {
                        if iszero(and(digits, 0x00000000000000000000000000800000)) {
                            if iszero(and(digits, 0x00000000000000000000000000400000)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 55))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 55))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 55))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x4b0, v)
                }
                // Chain 56.
                {
                    let v := mload(0x4d0)
                    if iszero(and(threes, 0x00000000000000000000000000000100)) {
                        if iszero(and(digits, 0x00000000000000000000000000000200)) {
                            if iszero(and(digits, 0x00000000000000000000000000000100)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 56))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 56))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 56))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x4c0, v)
                }
                // Chain 57.
                {
                    let v := mload(0x4e0)
                    if iszero(and(threes, 0x00000000000000000000000000000400)) {
                        if iszero(and(digits, 0x00000000000000000000000000000800)) {
                            if iszero(and(digits, 0x00000000000000000000000000000400)) {
                                mstore(0xf0, v)
                                mstore(0x100, shl(248, 57))
                                v := keccak256(0xd0, 0x40)
                            }
                            mstore(0xa0, v)
                            mstore(0xb0, shl(248, 57))
                            v := keccak256(0x80, 0x40)
                        }
                        mstore(0x20, v)
                        mstore(0x30, shl(248, 57))
                        v := keccak256(0, 0x40)
                    }
                    mstore(0x4d0, v)
                }
            }

            /// The root that `node` and the siblings at 0x4f0 reach. `tree` is `P | A` with the
            /// tree type and the layer's flag. `index` has the leaf index's four bytes as they are
            /// in the signature, in the place of `lo`, with ones in the 23 bits below the level.
            ///
            /// A level's node has the index shifted right by the level, little-endian. Each of
            /// its bytes takes the high bits of one byte of the leaf index and the low bits of
            /// the next, which are two shifts of `index` and a mask on each. The second shift is
            /// to the left by at least 8, so it brings the ones over the level and its mask
            /// writes the level too.
            ///
            /// A bit of the leaf index says whether the node is the right child. Bit `j` is bit
            /// `j % 8` of byte `j / 8`.
            function pathRoot(tree, index, node) -> root {
                // Level 1.
                {
                    let high := and(shr(1, index), 0x7f7f7f7f000000000000000000000000)
                    let low := and(shl(15, index), 0x80808000010000000000000000000000)
                    mstore(0, or(tree, or(high, low)))
                }
                switch and(index, 0x01000000000000000000000000000000)
                case 0 {
                    mstore(0x20, node)
                    mstore(0x30, mload(0x4f0))
                }
                default {
                    mstore(0x20, mload(0x4f0))
                    mstore(0x30, node)
                }
                // Level 2.
                {
                    let high := and(shr(2, index), 0x3f3f3f3f000000000000000000000000)
                    let low := and(shl(14, index), 0xc0c0c000020000000000000000000000)
                    mstore(0x80, or(tree, or(high, low)))
                }
                switch and(index, 0x02000000000000000000000000000000)
                case 0 {
                    mstore(0xa0, keccak256(0, 0x40))
                    mstore(0xb0, mload(0x500))
                }
                default {
                    mstore(0xa0, mload(0x500))
                    mstore(0xb0, keccak256(0, 0x40))
                }
                // Level 3.
                {
                    let high := and(shr(3, index), 0x1f1f1f1f000000000000000000000000)
                    let low := and(shl(13, index), 0xe0e0e000030000000000000000000000)
                    mstore(0, or(tree, or(high, low)))
                }
                switch and(index, 0x04000000000000000000000000000000)
                case 0 {
                    mstore(0x20, keccak256(0x80, 0x40))
                    mstore(0x30, mload(0x510))
                }
                default {
                    mstore(0x20, mload(0x510))
                    mstore(0x30, keccak256(0x80, 0x40))
                }
                // Level 4.
                {
                    let high := and(shr(4, index), 0x0f0f0f0f000000000000000000000000)
                    let low := and(shl(12, index), 0xf0f0f000040000000000000000000000)
                    mstore(0x80, or(tree, or(high, low)))
                }
                switch and(index, 0x08000000000000000000000000000000)
                case 0 {
                    mstore(0xa0, keccak256(0, 0x40))
                    mstore(0xb0, mload(0x520))
                }
                default {
                    mstore(0xa0, mload(0x520))
                    mstore(0xb0, keccak256(0, 0x40))
                }
                // Level 5.
                {
                    let high := and(shr(5, index), 0x07070707000000000000000000000000)
                    let low := and(shl(11, index), 0xf8f8f800050000000000000000000000)
                    mstore(0, or(tree, or(high, low)))
                }
                switch and(index, 0x10000000000000000000000000000000)
                case 0 {
                    mstore(0x20, keccak256(0x80, 0x40))
                    mstore(0x30, mload(0x530))
                }
                default {
                    mstore(0x20, mload(0x530))
                    mstore(0x30, keccak256(0x80, 0x40))
                }
                // Level 6.
                {
                    let high := and(shr(6, index), 0x03030303000000000000000000000000)
                    let low := and(shl(10, index), 0xfcfcfc00060000000000000000000000)
                    mstore(0x80, or(tree, or(high, low)))
                }
                switch and(index, 0x20000000000000000000000000000000)
                case 0 {
                    mstore(0xa0, keccak256(0, 0x40))
                    mstore(0xb0, mload(0x540))
                }
                default {
                    mstore(0xa0, mload(0x540))
                    mstore(0xb0, keccak256(0, 0x40))
                }
                // Level 7.
                {
                    let high := and(shr(7, index), 0x01010101000000000000000000000000)
                    let low := and(shl(9, index), 0xfefefe00070000000000000000000000)
                    mstore(0, or(tree, or(high, low)))
                }
                switch and(index, 0x40000000000000000000000000000000)
                case 0 {
                    mstore(0x20, keccak256(0x80, 0x40))
                    mstore(0x30, mload(0x550))
                }
                default {
                    mstore(0x20, mload(0x550))
                    mstore(0x30, keccak256(0x80, 0x40))
                }
                // Level 8.
                mstore(0x80, or(tree, and(shl(8, index), 0xffffff00080000000000000000000000)))
                switch and(index, 0x80000000000000000000000000000000)
                case 0 {
                    mstore(0xa0, keccak256(0, 0x40))
                    mstore(0xb0, mload(0x560))
                }
                default {
                    mstore(0xa0, mload(0x560))
                    mstore(0xb0, keccak256(0, 0x40))
                }
                // Level 9.
                {
                    let high := and(shl(7, index), 0x7f7f7f00000000000000000000000000)
                    let low := and(shl(23, index), 0x80800000090000000000000000000000)
                    mstore(0, or(tree, or(high, low)))
                }
                switch and(index, 0x00010000000000000000000000000000)
                case 0 {
                    mstore(0x20, keccak256(0x80, 0x40))
                    mstore(0x30, mload(0x570))
                }
                default {
                    mstore(0x20, mload(0x570))
                    mstore(0x30, keccak256(0x80, 0x40))
                }
                // Level 10.
                {
                    let high := and(shl(6, index), 0x3f3f3f00000000000000000000000000)
                    let low := and(shl(22, index), 0xc0c000000a0000000000000000000000)
                    mstore(0x80, or(tree, or(high, low)))
                }
                switch and(index, 0x00020000000000000000000000000000)
                case 0 {
                    mstore(0xa0, keccak256(0, 0x40))
                    mstore(0xb0, mload(0x580))
                }
                default {
                    mstore(0xa0, mload(0x580))
                    mstore(0xb0, keccak256(0, 0x40))
                }
                // Level 11.
                {
                    let high := and(shl(5, index), 0x1f1f1f00000000000000000000000000)
                    let low := and(shl(21, index), 0xe0e000000b0000000000000000000000)
                    mstore(0, or(tree, or(high, low)))
                }
                switch and(index, 0x00040000000000000000000000000000)
                case 0 {
                    mstore(0x20, keccak256(0x80, 0x40))
                    mstore(0x30, mload(0x590))
                }
                default {
                    mstore(0x20, mload(0x590))
                    mstore(0x30, keccak256(0x80, 0x40))
                }
                // Level 12.
                {
                    let high := and(shl(4, index), 0x0f0f0f00000000000000000000000000)
                    let low := and(shl(20, index), 0xf0f000000c0000000000000000000000)
                    mstore(0x80, or(tree, or(high, low)))
                }
                switch and(index, 0x00080000000000000000000000000000)
                case 0 {
                    mstore(0xa0, keccak256(0, 0x40))
                    mstore(0xb0, mload(0x5a0))
                }
                default {
                    mstore(0xa0, mload(0x5a0))
                    mstore(0xb0, keccak256(0, 0x40))
                }
                // Level 13.
                {
                    let high := and(shl(3, index), 0x07070700000000000000000000000000)
                    let low := and(shl(19, index), 0xf8f800000d0000000000000000000000)
                    mstore(0, or(tree, or(high, low)))
                }
                switch and(index, 0x00100000000000000000000000000000)
                case 0 {
                    mstore(0x20, keccak256(0x80, 0x40))
                    mstore(0x30, mload(0x5b0))
                }
                default {
                    mstore(0x20, mload(0x5b0))
                    mstore(0x30, keccak256(0x80, 0x40))
                }
                // Level 14.
                {
                    let high := and(shl(2, index), 0x03030300000000000000000000000000)
                    let low := and(shl(18, index), 0xfcfc00000e0000000000000000000000)
                    mstore(0x80, or(tree, or(high, low)))
                }
                switch and(index, 0x00200000000000000000000000000000)
                case 0 {
                    mstore(0xa0, keccak256(0, 0x40))
                    mstore(0xb0, mload(0x5c0))
                }
                default {
                    mstore(0xa0, mload(0x5c0))
                    mstore(0xb0, keccak256(0, 0x40))
                }
                // Level 15.
                {
                    let high := and(shl(1, index), 0x01010100000000000000000000000000)
                    let low := and(shl(17, index), 0xfefe00000f0000000000000000000000)
                    mstore(0, or(tree, or(high, low)))
                }
                switch and(index, 0x00400000000000000000000000000000)
                case 0 {
                    mstore(0x20, keccak256(0x80, 0x40))
                    mstore(0x30, mload(0x5d0))
                }
                default {
                    mstore(0x20, mload(0x5d0))
                    mstore(0x30, keccak256(0x80, 0x40))
                }
                // Level 16.
                mstore(0x80, or(tree, and(shl(16, index), 0xffff0000100000000000000000000000)))
                switch and(index, 0x00800000000000000000000000000000)
                case 0 {
                    mstore(0xa0, keccak256(0, 0x40))
                    mstore(0xb0, mload(0x5e0))
                }
                default {
                    mstore(0xa0, mload(0x5e0))
                    mstore(0xb0, keccak256(0, 0x40))
                }
                root := keccak256(0x80, 0x40)
            }

            /// `pathRoot` for a leaf index of zero, which is the one of a proof of possession:
            /// every node is a left child with `lo` zero, so only the level changes in `P | A`.
            function pathRootAtZero(tree, node) -> root {
                mstore(0, tree)
                mstore(0x80, tree)
                // Level 1.
                mstore8(0x14, 1)
                mstore(0x20, node)
                mstore(0x30, mload(0x4f0))
                // Level 2.
                mstore8(0x94, 2)
                mstore(0xa0, keccak256(0, 0x40))
                mstore(0xb0, mload(0x500))
                // Level 3.
                mstore8(0x14, 3)
                mstore(0x20, keccak256(0x80, 0x40))
                mstore(0x30, mload(0x510))
                // Level 4.
                mstore8(0x94, 4)
                mstore(0xa0, keccak256(0, 0x40))
                mstore(0xb0, mload(0x520))
                // Level 5.
                mstore8(0x14, 5)
                mstore(0x20, keccak256(0x80, 0x40))
                mstore(0x30, mload(0x530))
                // Level 6.
                mstore8(0x94, 6)
                mstore(0xa0, keccak256(0, 0x40))
                mstore(0xb0, mload(0x540))
                // Level 7.
                mstore8(0x14, 7)
                mstore(0x20, keccak256(0x80, 0x40))
                mstore(0x30, mload(0x550))
                // Level 8.
                mstore8(0x94, 8)
                mstore(0xa0, keccak256(0, 0x40))
                mstore(0xb0, mload(0x560))
                // Level 9.
                mstore8(0x14, 9)
                mstore(0x20, keccak256(0x80, 0x40))
                mstore(0x30, mload(0x570))
                // Level 10.
                mstore8(0x94, 10)
                mstore(0xa0, keccak256(0, 0x40))
                mstore(0xb0, mload(0x580))
                // Level 11.
                mstore8(0x14, 11)
                mstore(0x20, keccak256(0x80, 0x40))
                mstore(0x30, mload(0x590))
                // Level 12.
                mstore8(0x94, 12)
                mstore(0xa0, keccak256(0, 0x40))
                mstore(0xb0, mload(0x5a0))
                // Level 13.
                mstore8(0x14, 13)
                mstore(0x20, keccak256(0x80, 0x40))
                mstore(0x30, mload(0x5b0))
                // Level 14.
                mstore8(0x94, 14)
                mstore(0xa0, keccak256(0, 0x40))
                mstore(0xb0, mload(0x5c0))
                // Level 15.
                mstore8(0x14, 15)
                mstore(0x20, keccak256(0x80, 0x40))
                mstore(0x30, mload(0x5d0))
                // Level 16.
                mstore8(0x94, 16)
                mstore(0xa0, keccak256(0, 0x40))
                mstore(0xb0, mload(0x5e0))
                root := keccak256(0x80, 0x40)
            }

            /// The root that the layer at 0x140 reaches. `pa` is `P | A` with `lo`, the leaf
            /// index, and the layer's flag. `tree` is `P | A` with the tree type and the flag.
            /// `index` is `lo` in its place, and `digits` the layer's digest.
            function layerRoot(pa, tree, index, digits) -> root {
                mstore(0, or(pa, 0x410000000000000000))
                mstore(0x80, or(pa, 0x210000000000000000))
                mstore(0xd0, or(pa, 0x10000000000000000))
                mstore(0x120, or(pa, 0x20000000000000000))
                chainEnds(digits)
                let leaf := keccak256(0x120, 960)
                switch index
                case 0 { root := pathRootAtZero(tree, leaf) }
                default {
                    root := pathRoot(tree, or(index, 0x0000000000fffffe0000000000000000), leaf)
                }
            }

            let free := mload(0x40)
            let saved := free
            if gt(free, 0x80) {
                if lt(saved, 0x5f0) { saved := 0x5f0 }
                mcopy(saved, 0x80, 0x570)
            }

            let sig := signature.offset
            let param := shl(128, publicKey)
            // The leaf index is little-endian in the signature and in `lo`, so its bytes are
            // never swapped.
            let index := and(shr(128, calldataload(sig)), 0xffffffff000000000000000000000000)
            let pa := or(param, index)

            // The bottom layer signs the message.
            calldatacopy(0x140, add(sig, 4), 1200)
            mstore(0, or(pa, 0xc0000000000000000))
            mstore(0x20, message)
            mstore(0x40, mload(0x140))
            let digits := shr(128, keccak256(0, 0x50))
            if isCodeword(digits) {
                let root := layerRoot(pa, or(param, 0x30000000000000000), index, digits)

                // The top layer signs the bottom tree's root, with the key of that tree's number:
                // the leaf index without its low 16 bits, so its bytes two places up.
                index := and(shl(16, index), 0xffffffff000000000000000000000000)
                pa := or(or(param, 0x80000000000000000000), index)
                calldatacopy(0x140, add(sig, 1204), 1200)
                mstore(0, or(pa, 0xc0000000000000000))
                mstore(0x20, root)
                mstore(0x30, mload(0x140))
                digits := shr(128, keccak256(0, 0x40))
                if isCodeword(digits) {
                    root := layerRoot(pa, or(param, 0x80030000000000000000), index, digits)
                    ok := iszero(shr(128, xor(root, publicKey)))
                }
            }

            if gt(free, 0x80) { mcopy(0x80, saved, 0x570) }
            mstore(0x40, free)
        }
    }
}
