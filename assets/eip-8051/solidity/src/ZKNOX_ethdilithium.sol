/**
 *
 */
/*ZZZZZZZZZZZZZZZZZZZKKKKKKKKK    KKKKKKKNNNNNNNN        NNNNNNNN     OOOOOOOOO     XXXXXXX       XXXXXXX                         ..../&@&#.       .###%@@@#, ..
/*Z:::::::::::::::::ZK:::::::K    K:::::KN:::::::N       N::::::N   OO:::::::::OO   X:::::X       X:::::X                      ...(@@* .... .           &#//%@@&,.
/*Z:::::::::::::::::ZK:::::::K    K:::::KN::::::::N      N::::::N OO:::::::::::::OO X:::::X       X:::::X                    ..*@@.........              .@#%%(%&@&..
/*Z:::ZZZZZZZZ:::::Z K:::::::K   K::::::KN:::::::::N     N::::::NO:::::::OOO:::::::OX::::::X     X::::::X                   .*@( ........ .  .&@@@@.      .@%%%%%#&@@.
/*ZZZZZ     Z:::::Z  KK::::::K  K:::::KKKN::::::::::N    N::::::NO::::::O   O::::::OXXX:::::X   X::::::XX                ...&@ ......... .  &.     .@      /@%%%%%%&@@#
/*        Z:::::Z      K:::::K K:::::K   N:::::::::::N   N::::::NO:::::O     O:::::O   X:::::X X:::::X                   ..@( .......... .  &.     ,&      /@%%%%&&&&@@@.
/*       Z:::::Z       K::::::K:::::K    N:::::::N::::N  N::::::NO:::::O     O:::::O    X:::::X:::::X                   ..&% ...........     .@%(#@#      ,@%%%%&&&&&@@@%.
/*      Z:::::Z        K:::::::::::K     N::::::N N::::N N::::::NO:::::O     O:::::O     X:::::::::X                   ..,@ ............                 *@%%%&%&&&&&&@@@.
/*     Z:::::Z         K:::::::::::K     N::::::N  N::::N:::::::NO:::::O     O:::::O     X:::::::::X                  ..(@ .............             ,#@&&&&&&&&&&&&@@@@*
/*    Z:::::Z          K::::::K:::::K    N::::::N   N:::::::::::NO:::::O     O:::::O    X:::::X:::::X                   .*@..............  . ..,(%&@@&&&&&&&&&&&&&&&&@@@@,
/*   Z:::::Z           K:::::K K:::::K   N::::::N    N::::::::::NO:::::O     O:::::O   X:::::X X:::::X                 ...&#............. *@@&&&&&&&&&&&&&&&&&&&&@@&@@@@&
/*ZZZ:::::Z     ZZZZZKK::::::K  K:::::KKKN::::::N     N:::::::::NO::::::O   O::::::OXXX:::::X   X::::::XX               ...@/.......... *@@@@. ,@@.  &@&&&&&&@@@@@@@@@@@.
/*Z::::::ZZZZZZZZ:::ZK:::::::K   K::::::KN::::::N      N::::::::NO:::::::OOO:::::::OX::::::X     X::::::X               ....&#..........@@@, *@@&&&@% .@@@@@@@@@@@@@@@&
/*Z:::::::::::::::::ZK:::::::K    K:::::KN::::::N       N:::::::N OO:::::::::::::OO X:::::X       X:::::X                ....*@.,......,@@@...@@@@@@&..%@@@@@@@@@@@@@/
/*Z:::::::::::::::::ZK:::::::K    K:::::KN::::::N        N::::::N   OO:::::::::OO   X:::::X       X:::::X                   ...*@,,.....%@@@,.........%@@@@@@@@@@@@(
/*ZZZZZZZZZZZZZZZZZZZKKKKKKKKK    KKKKKKKNNNNNNNN         NNNNNNN     OOOOOOOOO     XXXXXXX       XXXXXXX                      ...&@,....*@@@@@ ..,@@@@@@@@@@@@@&.
/*                                                                                                                                   ....,(&@@&..,,,/@&#*. .
/*                                                                                                                                    ......(&.,.,,/&@,.
/*                                                                                                                                      .....,%*.,*@%
/*                                                                                                                                    .#@@@&(&@*,,*@@%,..
/*                                                                                                                                    .##,,,**$.,,*@@@@@%.
/*                                                                                                                                     *(%%&&@(,,**@@@@@&
/*                                                                                                                                      . .  .#@((@@(*,**
/*                                                                                                                                             . (*. .
/*                                                                                                                                              .*/
///* Copyright (C) 2025 - Renaud Dubois, Simon Masson - This file is part of ZKNOX project
///* License: This software is licensed under MIT License
///* This Code may be reused including this header, license and copyright notice.
///* See LICENSE file at the root folder of the project.
///* FILE: ZKNOX_ethdilithium.sol
///* Description: Compute ethereum friendly version of dilithium verification
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./ZKNOX_NTT_dilithium.sol";
import "./ZKNOX_dilithium_core.sol";
import "./ZKNOX_dilithium_utils.sol";
import "./ZKNOX_SampleInBall.sol";
import "./ZKNOX_shake.sol";
import {
    q,
    ZKNOX_Expand,
    ZKNOX_Expand_Vec,
    ZKNOX_Expand_Mat,
    ZKNOX_MatVecProductDilithium,
    ZKNOX_VECMULMOD,
    ZKNOX_VECSUBMOD,
    ID_keccak,
    omega,
    gamma_1_minus_beta
} from "./ZKNOX_dilithium_utils.sol";

import {useHintDilithium} from "./ZKNOX_hint.sol";

contract ZKNOX_ethdilithium {
    function verify(PubKey memory pk, bytes memory m, Signature memory signature, bytes memory ctx)
        external
        view
        returns (bool)
    {
        // Step 1: check ctx length
        if (ctx.length > 255) {
            revert("ctx bytes must have length at most 255");
        }

        // Step 2: m_prime = 0x00 || len(ctx) || ctx || m
        bytes memory m_prime = abi.encodePacked(bytes1(0), bytes1(uint8(ctx.length)), ctx, m);

        // Step 3: delegate to internal verify
        return verify_internal(pk, m_prime, signature);
    }

    function verify_internal(PubKey memory pk, bytes memory m_prime, Signature memory signature)
        internal
        view
        returns (bool)
    {
        uint256 i;
        uint256 j;

        // FIRST CORE STEP
        (bool foo, uint256 norm_h, uint256[][] memory h, uint256[][] memory z) = dilithium_core_1(signature);

        if (foo == false) {
            return false;
        }
        if (norm_h > omega) {
            return false;
        }
        for (i = 0; i < 4; i++) {
            for (j = 0; j < 256; j++) {
                uint256 zij = z[i][j];
                if (zij > gamma_1_minus_beta && (q - zij) > gamma_1_minus_beta) {
                    return false;
                }
            }
        }

        // C_NTT
        uint256[] memory c_ntt = sampleInBallKeccakPRNG(signature.c_tilde, tau, q);
        c_ntt = ZKNOX_NTTFW(c_ntt);

        // t1_new
        uint256[][] memory t1_new = ZKNOX_Expand_Vec(pk.t1);

        // SECOND CORE STEP
        bytes memory w_prime_bytes = dilithium_core_2(pk, z, c_ntt, h, t1_new);

        // FINAL HASH
        KeccakPRNG memory prng = initPRNG(abi.encodePacked(pk.tr, m_prime));
        bytes32 out1 = prng.pool;
        refill(prng);
        bytes32 out2 = prng.pool;
        prng = initPRNG(abi.encodePacked(out1, out2, w_prime_bytes));
        bytes32 final_hash = prng.pool;
        return final_hash == bytes32(signature.c_tilde);
    }
}
//end of contract
