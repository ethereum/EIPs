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
///* FILE: ZKNOX_ethfalcon.sol
///* Description: Compute ethereum friendly version of falcon verification
/**
 *
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./ZKNOX_common.sol";
import "./ZKNOX_IVerifier.sol";
import "./ZKNOX_falcon_utils.sol";
import "./ZKNOX_falcon_core.sol";
import "./ZKNOX_HashToPoint.sol";

/// @title ZKNOX_ethfalcon
/// @notice A contract to verify ETHFALCON signatures
/// @dev ETHFALCON is FALCON with a Keccak-CTR PRNG instead of shake for gas cost efficiency.

/// @custom:experimental This library is not audited yet, do not use in production.

contract ZKNOX_ethfalcon is ISigVerifier {
    function CheckParameters(bytes memory salt, uint256[] memory s2, uint256[] memory ntth)
        internal
        pure
        returns (bool)
    {
        if (ntth.length != falcon_S256) return false; //"Invalid public key length"
        if (salt.length != 40) return false; //CVETH-2025-080201: control salt length to avoid potential forge
        if (s2.length != falcon_S256) return false; //"Invalid salt length"

        return true;
    }

    /// @notice Compute the  ethfalcon verification function

    /// @param h the hash of message to be signed, expected length is 32 bytes
    /// @param salt the message to be signed, expected length is 40 bytes
    /// @param s2 second part of the signature in Compacted representation (see IO part of README for encodings specification), expected length is 32 uint256
    /// @param ntth public key in the ntt domain, compacted 16  coefficients of 16 bits per word
    /// @return result boolean result of the verification
    function verify(
        bytes memory h, //a 32 bytes hash
        bytes memory salt, // compacted signature salt part
        uint256[] memory s2, // compacted signature s2 part
        uint256[] memory ntth // public key, compacted representing coefficients over 16 bits
    )
        external
        view
        returns (bool result)
    {
        // if (h.length != 32) return false;
        if (salt.length != 40) {
            revert("invalid salt length");
            //return false;
        } //CVETH-2025-080201: control salt length to avoid potential forge
        if (s2.length != falcon_S256) {
            revert("invalid s2 length");
            //return false;
        } //"Invalid salt length"
        if (ntth.length != falcon_S256) {
            revert("invalid ntth length");
            //return false;
        } //"Invalid public key length"

        uint256[] memory hashed = hashToPointRIP(salt, h);

        result = falcon_core(s2, ntth, hashed);
        //if (result == false) revert("wrong sig");

        return result;
    }

    function GetPublicKey(address _from) external view override returns (uint256[] memory Kpub) {
        Kpub = new uint256[](32);

        assembly {
            let offset := Kpub

            for { let i := 0 } gt(1024, i) { i := add(i, 32) } {
                //read the 32 words
                offset := add(offset, 32)

                extcodecopy(_from, offset, i, 32) //psi_rev[m+i])
            }
        }
        return Kpub;
    }
} //end of contract ZKNOX_falcon_compact
