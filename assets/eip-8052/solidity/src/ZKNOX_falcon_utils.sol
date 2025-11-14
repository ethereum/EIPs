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
///* FILE: ZKNOX_falcon_utils.sol
///* Description: Auxiliary functions for falcon
/**
 *
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

uint256 constant mask16 = 0xffff;
uint256 constant chunk16Byword = 16; //number of 1§ bits chunks in a word of 256 bits
uint256 constant falcon_S256 = 32; //number of 256 bits word in a polynomial
//implemented hash identifiers
uint256 constant ID_keccak = 0x00;
uint256 constant ID_tetration = 0x01;

uint256 constant _FALCON_WORD256_S = 32;
uint256 constant _FALCON_WORD32_S = 512;

//FALCON CONSTANTS
uint256 constant n = 512;
uint256 constant nm1modq = 12265;
uint256 constant sigBound = 34034726;
uint256 constant sigBytesLen = 666;
uint256 constant q = 12289;
uint256 constant qs1 = 6144; // q >> 1;
uint256 constant kq = 61445;

function Swap(uint256[] memory Pol) pure returns (uint256[] memory Mirror) {
    Mirror = new uint256[](512);
    for (uint256 i = 0; i < 512; i++) {
        Mirror[511 - i] = Pol[i];
    }
}

//return the compacted version of an expanded polynomial
function _ZKNOX_NTT_Compact(uint256[] memory a) pure returns (uint256[] memory b) {
    b = new uint256[](32);

    assembly {
        let aa := a
        let bb := add(b, 32)
        for { let i := 0 } gt(512, i) { i := add(i, 1) } {
            aa := add(aa, 32)
            let bi := add(bb, mul(32, shr(4, i))) //shr(4,i)*32 !=shl(1,i)
            mstore(bi, xor(mload(bi), shl(shl(4, and(i, 0xf)), mload(aa))))
        }
    }

    return b;
}

//return the expanded version of a compacted polynomial
function _ZKNOX_NTT_Expand(uint256[] memory a) pure returns (uint256[] memory b) {
    b = new uint256[](512);

    /*
    for (uint256 i = 0; i < 32; i++) {
        uint256 ai = a[i];
        for (uint256 j = 0; j < 16; j++) {
            b[(i << 4) + j] = (ai >> (j << 4)) & mask16;
        }
    }
    */

    assembly {
        let aa := a
        let bb := add(b, 32)
        for { let i := 0 } gt(32, i) { i := add(i, 1) } {
            aa := add(aa, 32)
            let ai := mload(aa)

            for { let j := 0 } gt(16, j) { j := add(j, 1) } {
                mstore(add(bb, mul(32, add(j, shl(4, i)))), and(shr(shl(4, j), ai), 0xffff)) //b[(i << 4) + j] = (ai >> (j << 4)) & mask16;
            }
        }
    }

    return b;
}

//decompress a polynomial starting at offset byte of buf
function _ZKNOX_NTT_Decompress(bytes memory buf, uint256 offset) pure returns (uint256[] memory) {
    uint256[] memory x = new uint256[](512);
    uint32 acc = 0;
    uint256 acc_len = 0;
    uint256 u = 0;
    uint256 cpt = offset; //start with offset 1 to prune 0x09 header

    while (u < n) {
        acc = (acc << 8) | uint32(uint8(buf[cpt]));
        cpt++;

        acc_len += 8;
        if (acc_len >= 14) {
            uint32 w;

            acc_len -= 14;
            w = (acc >> acc_len) & 0x3FFF;
            if (w >= 12289) {
                revert("wrong coeff");
            }
            x[u] = uint256(w);
            u++;
        } //end if
    } //end while
    if ((acc & ((1 << acc_len) - 1)) != 0) {
        revert();
    }

    //console.log("last read kpub", uint8(buf[cpt-1]));
    return x;
}
