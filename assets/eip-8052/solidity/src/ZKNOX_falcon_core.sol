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
///* FILE: ZKNOX_falcon_core.sol
///* Description: verify falcon core component
/**
 *
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./ZKNOX_falcon_utils.sol";
import "./ZKNOX_NTT_falcon.sol";

function falcon_checkPolynomialRange(uint256[] memory polynomial, bool is_compact) pure returns (bool) {
    uint256[] memory a;
    if (is_compact == false) {
        a = _ZKNOX_NTT_Expand(polynomial);
    } else {
        a = polynomial;
    }
    for (uint256 i = 0; i < a.length; i++) {
        if (a[i] > q) return false;
    }

    return true;
}

function falcon_normalize(
    uint256[] memory s1,
    uint256[] memory s2,
    uint256[] memory hashed // result of hashToPoint(signature.salt, msgs, q, n);
)
    pure
    returns (bool result)
{
    uint256 norm = 0;

    assembly {
        for { let offset := 32 } gt(16384, offset) { offset := add(offset, 32) } {
            let s1i := addmod(mload(add(hashed, offset)), sub(q, mload(add(s1, offset))), q) //s1[i] = addmod(hashed[i], q - s1[i], q);
            let cond := gt(s1i, qs1) //s1[i] > qs1 ?
            s1i := add(mul(cond, sub(q, s1i)), mul(sub(1, cond), s1i))
            norm := add(norm, mul(s1i, s1i))
        }

        //s1 = _ZKNOX_NTT_Expand(s2); //avoiding another memory declaration
        let aa := s2
        let bb := add(s1, 32)
        for { let i := 0 } gt(32, i) { i := add(i, 1) } {
            aa := add(aa, 32)
            let ai := mload(aa)

            for { let j := 0 } gt(16, j) { j := add(j, 1) } {
                mstore(add(bb, mul(32, add(j, shl(4, i)))), and(shr(shl(4, j), ai), 0xffff)) //b[(i << 4) + j] = (ai >> (j << 4)) & mask16;
            }
        }

        for { let offset := add(s1, 32) } gt(16384, offset) { offset := add(offset, 32) } {
            let s1i := mload(offset) //s1[i]
            let cond := gt(s1i, qs1) //s1[i] > qs1 ?
            s1i := add(mul(cond, sub(q, s1i)), mul(sub(1, cond), s1i))
            norm := add(norm, mul(s1i, s1i))
        }

        result := gt(sigBound, norm) //norm < SigBound ?
    }

    return result;
}

/// @notice Compute the core falcon verification function, compacted input
/// @param s2 second part of the signature in Compacted representation (see IO part of README for encodings specification)
/// @param ntth public key in the ntt domain, compacted 16  coefficients of 16 bits per word
/// @param hashed result of hashToPoint(signature.salt, msgs, q, n);
/// @return result boolean result of the verification

function falcon_core(
    uint256[] memory s2,
    uint256[] memory ntth, // public key, compacted 16  coefficients of 16 bits per word
    uint256[] memory hashed // result of hashToPoint(signature.salt, msgs, q, n);
)
    view
    returns (bool result)
{
    if (hashed.length != 512) return false;
    if (s2.length != 32) return false; //"Invalid signature length"

    result = false;

    uint256[] memory s1 = _ZKNOX_NTT_Expand(_ZKNOX_NTT_HALFMUL_Compact(s2, ntth)); //build on top of specific NTT

    return falcon_normalize(s1, s2, hashed);
}
