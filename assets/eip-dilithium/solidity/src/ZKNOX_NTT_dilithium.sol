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
///* FILE: ZKNOX_NTT.sol
///* Description: Compute Negative Wrap Convolution NTT as specified in EIP-NTT
/**
 *
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./ZKNOX_dilithium_utils.sol";

// NTT_FW as specified by EIP, statefull version
//address apsirev: address of the contract storing the powers of psi, expanded
function ZKNOX_NTTFW(uint256[] memory a, address apsirev) view returns (uint256[] memory) {
    uint256 t = n;
    uint256 m = 1;

    uint256[1] memory S;

    assembly ("memory-safe") {
        for {} gt(n, m) {} {
            //while(m<n)
            t := shr(1, t)
            for { let i := 0 } gt(m, i) { i := add(i, 1) } {
                let j1 := shl(1, mul(i, t))
                let j2 := sub(add(j1, t), 1) //j2=j1+t-1;

                extcodecopy(apsirev, S, mul(add(i, m), 32), 32) //psi_rev[m+i]
                for { let j := j1 } gt(add(j2, 1), j) { j := add(j, 1) } {
                    let a_aj := add(a, mul(add(j, 1), 32)) //address of a[j]
                    let U := mload(a_aj)

                    a_aj := add(a_aj, mul(t, 32)) //address of a[j+t]
                    let V := mulmod(mload(a_aj), mload(S), q)
                    mstore(a_aj, addmod(U, sub(q, V), q))
                    a_aj := sub(a_aj, mul(t, 32)) //back to address of a[j]
                    mstore(a_aj, addmod(U, V, q))
                }
            }
            m := shl(1, m) //m=m<<1
        }
    }
    return a;
}

// NTT_FW as specified by EIP, statefull version
//address apsirev: address of the contract storing the powers of psi, compact
function ZKNOX_NTTFW_Compact(uint256[] memory a, address apsirev) view returns (uint256[] memory) {
    uint256 t = n;
    uint256 m = 1;

    uint256[1] memory S;

    assembly ("memory-safe") {
        for {} gt(n, m) {} {
            //while(m<n)
            t := shr(1, t)
            for { let i := 0 } gt(m, i) { i := add(i, 1) } {
                let j1 := shl(1, mul(i, t))
                let j2 := sub(add(j1, t), 1) //j2=j1+t-1;

                extcodecopy(apsirev, S, mul(add(i, m), 4), 4) //psi_rev[m+i]
                for { let j := j1 } gt(add(j2, 1), j) { j := add(j, 1) } {
                    let a_aj := add(a, mul(add(j, 1), 32)) //address of a[j]
                    let U := mload(a_aj)

                    a_aj := add(a_aj, mul(t, 32)) //address of a[j+t]
                    let V := mulmod(mload(a_aj), mload(S), q)
                    mstore(a_aj, addmod(U, sub(q, V), q))
                    a_aj := sub(a_aj, mul(t, 32)) //back to address of a[j]
                    mstore(a_aj, addmod(U, V, q))
                }
            }
            m := shl(1, m) //m=m<<1
        }
    }
    return a;
}

// NTT_INV as specified by EIP, stateful version
//address apsiinvrev: address of the contract storing the powers of psi^-1
function ZKNOX_NTTINV(uint256[] memory a, address apsiinvrev) view returns (uint256[] memory) {
    uint256 t = 1;
    uint256 m = a.length;

    uint256[1] memory S;

    assembly ("memory-safe") {
        for {} gt(m, 1) {} {
            // while(m > 1)
            let j1 := 0
            let h := shr(1, m) //uint h = m>>1;
            for { let i := 0 } gt(h, i) { i := add(i, 1) } {
                //while(m<n)
                let j2 := sub(add(j1, t), 1)
                extcodecopy(apsiinvrev, S, mul(add(i, h), 32), 32) //psi_rev[m+i]
                for { let j := j1 } gt(add(j2, 1), j) { j := add(j, 1) } {
                    let a_aj := add(a, mul(add(j, 1), 32)) //address of a[j]
                    let U := mload(a_aj) //U=a[j];
                    a_aj := add(a_aj, mul(t, 32)) //address of a[j+t]
                    let V := mload(a_aj)
                    mstore(a_aj, mulmod(addmod(U, sub(q, V), q), mload(S), q)) //a[j+t]=mulmod(addmod(U,q-V,q),S[0],q);
                    a_aj := sub(a_aj, mul(t, 32)) //back to address of a[j]
                    mstore(a_aj, addmod(U, V, q)) // a[j]=addmod(U,V,q);
                } //end loop j
                j1 := add(j1, shl(1, t)) //j1=j1+2t
            } //end loop i
            t := shl(1, t)
            m := shr(1, m)
        } //end while

        for { let j := 0 } gt(mload(a), j) { j := add(j, 1) } {
            //j<n
            let a_aj := add(a, mul(add(j, 1), 32)) //address of a[j]
            mstore(a_aj, mulmod(mload(a_aj), nm1modq, q))
        }
    }

    return a;
}
