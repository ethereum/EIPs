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
///* FILE: ZKNOX_falcon_encodings.sol
///* Description: Decompression function of falcon verification
/**
 *
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./ZKNOX_falcon_utils.sol";
//import {Test, console} from "forge-std/Test.sol";

uint256 constant max_in_len = 666;

//decompress signature starting from offset in buf
//compared to _ZKNOX_NTT_Decompress, extra testing conditions are set if norm gonna blow
//because of a too high coefficient
function _decompress_sig(bytes memory buf, uint256 offset) pure returns (uint256[] memory) {
    uint256[] memory x = new uint256[](512);

    uint32 acc = 0;
    uint256 acc_len = 0;
    uint256 v = offset;

    for (uint256 u = 0; u < n; u++) {
        uint256 s;
        uint256 m;

        /*
        * Get next eight bits: sign and low seven bits of the
        * absolute value.
        */

        assembly {
            let temp := byte(0, mload(add(add(buf, 32), v)))
            acc := or(shl(8, acc), temp)
            v := add(v, 1)
            let b := shr(acc_len, acc)
            s := and(b, 128)
            m := and(b, 127)

            for {} eq(0, 0) {} {
                if eq(0, acc_len) {
                    acc := or(shl(8, acc), byte(0, mload(add(add(buf, 32), v))))
                    v := add(1, v)
                    acc_len := 8
                }
                acc_len := sub(acc_len, 1)

                if and(shr(acc_len, acc), 1) {
                    // if (((acc >> acc_len) & 1) != 0)
                    break
                }
                //if eq(0, and(1, shr(acc_len, acc)) )   {break}
                m := add(m, 128) //m += 128;
                if gt(m, 2047) {
                    let ptr := mload(0x40) // Get free memory pointer
                    // Store the error message "coeff to big" in memory
                    mstore(ptr, 0x636f65666620746f206269670000000000000000000000000000000000000000) // "coeff to big" in hex
                    revert(ptr, 12) // Revert with 12 bytes (length of "coeff to big")
                }
            }
        } //end void loop for

        /*
        * "-0" is forbidden.
        */
        //	if ( ((s==0) && (m==0)) ) {//TODO: replace
        //		revert("incorrect zero encoding");
        //	}

        assembly {
            let temp := m // x[u] = m;
            if eq(0x80, s) {
                //if (s == 0x80)
                temp := sub(q, m) // x[u] = q - m;
            }
            mstore(add(add(x, 32), mul(32, u)), temp)
        }
    } //end loop u

    //console.log("last read sig:",uint8(buf[v]));
    if ((v - offset) >= max_in_len) {
        revert("too long");
    }

    return x;
}

/*
	 * Decode NIST KAT made of
     * the encoded public key:0x09+ public key compressed value
     * the signature bundled with the message. Format is:
	 *   signature length     slen encoded on 2 bytes, big-endian
	 *   nonce                40 bytes
	 *   message              mlen bytes
	 *   signature            slen bytes
	 */
function decompress_KAT(bytes memory pk, bytes memory sm, uint256 mlen)
    pure
    returns (uint256[] memory h, uint256[] memory s2, bytes memory salt, bytes memory message)
{
    uint256 slen = (uint256(uint8(sm[0])) << 8) + uint256(uint8(sm[1]));

    /*
    * Decode public key.
    */
    if (pk[0] != 0x09) {
        revert("wrong public key encoding");
    }
    h = _ZKNOX_NTT_Decompress(pk, 1); //decompressing kpub, assuming first byte is 0x09, so offset=1

    uint256 i;
    salt = new bytes(40);

    for (i = 0; i < 40; i++) {
        salt[i] = sm[i + 2];
    }
    message = new bytes(mlen);
    for (uint256 j = 0; j < mlen; j++) {
        message[j] = sm[j + 42];
    }

    if (sm[2 + 40 + mlen] != 0x29) {
        revert("wrong header sigbytes");
    }

    s2 = _decompress_sig(sm, 2 + 40 + mlen + 1);

    return (h, s2, salt, message);
}
