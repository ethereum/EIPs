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
///* FILE: ZKNOX_HashToPoint.sol
///* Description: Compute HashToPoint (three versions: NIST, RIP and TETRATION)
/**
 *
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./ZKNOX_falcon_utils.sol";
import "./ZKNOX_shake.sol";
//import {Test, console} from "forge-std/Test.sol";
//import "./ZKNOX_display.sol";

uint256 constant MASK_2BYTES = uint256(0xFFFF);

function hashToPointRIP(bytes memory salt, bytes memory msgHash) pure returns (uint256[] memory output) {
    output = new uint256[](n);

    bytes32 state;

    // Initial state
    state = keccak256(abi.encodePacked(msgHash, salt));
    bytes memory extendedState = abi.encodePacked(state, uint64(0x00));

    assembly {
        let counter := 0
        let i := 0
        let offset := add(output, 32)
        let extendedAdress := add(extendedState, 64)
        for {} lt(i, n) {} {
            let buffer := keccak256(add(extendedState, 32), 40)
            for { let j := 240 } gt(666, j) { j := sub(j, 16) } {
                let chunk := and(shr(j, buffer), 0xffff)
                if lt(chunk, kq) {
                    mstore(offset, mod(chunk, q))
                    offset := add(offset, 32)
                    i := add(i, 1)
                    if eq(i, 512) { break }
                }
            }

            counter := add(counter, 6277101735386680763835789423207666416102355444464034512896) //counter+=1, shift by 192 to increment directly memory buffer by a 64 bits counter.
            mstore(extendedAdress, counter)
        }
    }
}

function splitToHex(bytes32 x) pure returns (uint16[16] memory) {
    // splits a byte32 into hex
    uint16[16] memory res;
    for (uint256 i = 0; i < 16; i++) {
        res[i] = uint16(uint256(x) >> ((15 - i) * 16));
    }
    return res;
}

function hashToPointNIST(bytes memory salt, bytes memory msgHash) pure returns (uint256[] memory) {
    // SALT AND MSG ARE SWAPPED!
    uint256[] memory hashed = new uint256[](512);
    uint256 i = 0;
    uint256 j = 0;
    ctx_shake memory ctx;
    bytes memory tmp;
    ctx = shake_update(ctx, abi.encodePacked(salt, msgHash));
    ctx = shake_pad(ctx);
    (ctx, tmp) = shake_squeeze(ctx, _RATE);
    while (i < n) {
        if (j == _RATE) {
            (ctx, tmp) = shake_squeeze(ctx, _RATE);
            j = 0;
        }
        uint256 dibytes = uint256(uint8(tmp[j + 1])) + (uint256(uint8(tmp[j])) << 8);
        if (dibytes < kq) {
            hashed[i] = dibytes % q;
            i++;
        }
        j += 2;
    }
    //hashed=Swap(hashed);
    return hashed;
}

//Use for Poc only, as this XOF doesn't respect separation domain for input and output of internal state
//CVETH-2025-080203
function hashToPointTETRATION(bytes memory salt, bytes memory msgHash) pure returns (uint256[] memory) {
    uint256[] memory hashed = new uint256[](512);
    uint256 i = 0;
    uint256 j = 0;
    bytes32 tmp = keccak256(abi.encodePacked(msgHash, salt));
    uint16[16] memory sample = splitToHex(tmp);

    while (i < n) {
        if (j == 16) {
            tmp = keccak256(abi.encodePacked(tmp));
            sample = splitToHex(tmp);
            j = 0;
        }
        if (sample[j] < kq) {
            hashed[i] = sample[j] % q;
            i++;
        }
        j++;
    }
    return hashed;
}
