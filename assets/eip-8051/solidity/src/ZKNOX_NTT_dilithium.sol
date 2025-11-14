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

//// internal version to spare call data cost

function ZKNOX_NTTFW(uint256[] memory a) pure returns (uint256[] memory) {
    uint256[32] memory psirev = [
        uint256(0x4f066b004fe0330053df73004f062b003965690039756700495e0200000001),
        0x6d3dc8000881920070894a0039728300207fe40028edb000360dd50076b1ae,
        0x6b7d81000a52ee00794034004a18a70066528a0028a3d20041e0b4004c7294,
        0x22d8d5002af69700492bb7007611bd001649ee002571df001a2877004e9f1d,
        0x11b2c3003887f7002010a20050685f004926730029d13f0030911e0036f72a,
        0x20e612003177f400428cd4001f9d15004a5f350010b72c000e2bed000603a4,
        0x439a1c0065ad050062564a003952f60049553f00736681001ad87300341c1d,
        0x1c5b7000330e2b001c496e002c83da003b0e6d00087f380030b6220053aa5f,
        0x7bb17500503ee1004eb2ea003fd54c003ac6ef0057a93000137eb9002ee3f1,
        0x3f7288006ef1f50052589c002ae59b0045a6d4001d90a2001ef256002648b4,
        0x4cff12002592ec000296d800773e9e0052aca9001187ba00075d5900175102,
        0x31b859004e48170003978f001a7e79004f16c1001e54e6004aa58200404ce8,
        0x5bd532006c09d100400c7e0035225e005d787a005b63d0001b4827005884cc,
        0x337caa002ca4f8006d285c003b882000097a6c002e534c00258ecb006bc4d3,
        0x78de660075e82600234a86004af6700055795d0028f186005585360014b2a0,
        0x1a9e7b005dbecb00628b3400459b7e005bf3da000f6e17007adf590005528c,
        0x2a4e78007ef8f50064b5fe002898380069a8ef00574b3c006257c5000006d9,
        0x4728af004dc04e005cd5b400437ff800435e870009b7ff000154a800120a23,
        0x46829800437f3100185d960061ab98005a6d80000f66d5000c8d0d007f735d,
        0x5a68b0007c0db30009b4340049b0e300465d8d0028de06004bd57900662960,
        0x4f5859007bc7590048c39b00246e39006585910021762a0064d3d500409ba9,
        0x7faf800013232e002854240030c31c00454df20012eb670023092300392db2,
        0x5e061e006be1cc00095b76006b33750026587a007e832c00022a0b002dbfcb,
        0x5ea06c007361b8006330bb001f1d68004ae53c003da60400628c370078e00d,
        0x56038e00080e6d006de0240008f2010060d772005ba4ff00201fc600671ac7,
        0x63e1e30074d0bd006dbfd40007c017006a9dfa002603bd001e6d3e00695688,
        0x427e23000b7009003f4cf50058018c002decd4002867ba007ab60d00519573,
        0x4c76c80011c14e001ef20600196926001a4b5d0067395700273333003cbd37,
        0x741e780008526000034760003352d6002e1669006af66c007fb19a003cf42f,
        0x68c559000223d400345824000d1ff000776d0b0007c0f1006f0a11002f6316,
        0x79e1fe002ca5e60065adb30051e0ed005e69420023fc65002faa32005e8885,
        0x74b6d70010170e0073f1ce001cfe1400464ade00433aac0035e1dd007b4064
    ];

    uint256 t = n;
    uint256 m = 1;

    uint256 S;

    assembly ("memory-safe") {
        for {} gt(n, m) {} {
            //while(m<n)
            t := shr(1, t)

            for { let i := 0 } gt(m, i) { i := add(i, 1) } {
                let j1 := shl(1, mul(i, t))
                let j2 := sub(add(j1, t), 1) //j2=j1+t-1;

                //uint256 S = psirev[m+i];
                S := mload(add(psirev, mul(32, shr(3, add(m, i))))) //line index+load(line)
                S := and(shr(mul(32, and(add(m, i), 0x7)), S), 0xffffffff) //shift word in line

                for { let j := j1 } gt(add(j2, 1), j) { j := add(j, 1) } {
                    let a_aj := add(a, mul(add(j, 1), 32)) //address of a[j]
                    let U := mload(a_aj)

                    a_aj := add(a_aj, mul(t, 32)) //address of a[j+t]
                    let V := mulmod(mload(a_aj), S, q)
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

function ZKNOX_NTTINV(uint256[] memory a) pure returns (uint256[] memory) {
    uint256[32] memory psirev = [
        uint256(0x30d9d6002c008e002fffce0030d99600466a9a00467a98003681ff00000001),
        0x92e530049d22c0056f251005f601d00466d7e000f56b700775e6f0012a239,
        0x3140e40065b78a005a6e22006996130009ce440036b44a0054e96a005d072c,
        0x336d6d003dff4d00573c2f00198d770035c75a00069fcd00758d1300146280,
        0x2c35a2004f29df007760c90044d19400535c2700639693004cd1d600638491,
        0x4bc3e40065078e000c798000368ac200468d0b001d89b7001a32fc003c45e5,
        0x79dc5d0071b414006f28d5003580cc006042ec003d532d004e680d005ef9ef,
        0x48e8d7004f4ee300560ec20036b98e002f77a2005fcf5f0047580a006e2d3e,
        0x7a8d75000500a8007071ea0023ec27003a4483001d54cd0022213600654186,
        0x6b2d61002a5acb0056ee7b002a66a40034e991005c957b0009f7db0007019b,
        0x141b2e005a513600518cb500766595004457e10012b7a500533b09004c6357,
        0x275b35006497da00247c3100226787004abda3003fd3830013d63000240acf,
        0x3f931900353a7f00618b1b0030c94000656188007c4872003197ea004e27a8,
        0x688eff007882a8006e5847002d33580008a163007d4929005a4d150032e0ef,
        0x59974d0060edab00624f5f003a392d0054fa66002d87650010ee0c00406d79,
        0x50fc10006c6148002836d10045191200400ab500312d17002fa12000042e8c,
        0x49f9d0049fe24003ca555003995230062e1ed000bee33006fc8f3000b292a,
        0x21577c005035cf005be39c002176bf002dff14001a324e00533a1b0005fe03,
        0x507ceb0010d5f000781f10000872f60072c011004b87dd007dbc2d00171aa8,
        0x42ebd200002e670014e9950051c998004c8d2b007c98a100778da1000bc189,
        0x4322ca0058acce0018a6aa006594a4006676db0060edfb006e1eb300336939,
        0x2e4a8e000529f4005778470051f32d0027de750040930c00746ff8003d61de,
        0x168979006172c30059dc440015420700781fea0012202d000b0f44001bfe1e,
        0x18c53a005fc03b00243b02001f088f0076ee000011ffdd0077d1940029dc73,
        0x6fff4001d53ca004239fd0034fac50060c299001caf46000c7e4900213f95,
        0x522036007db5f600015cd5005987870014ac8c0076848b0013fe350021d9e3,
        0x46b24f005cd6de006cf49a003a920f004f1ce500578bdd006cbcd300003081,
        0x3f4458001b0c2c005e69d7001a5a70005b71c800371c66000418a8003087a8,
        0x19b6a100340a88005701fb0039827400362f1e00762bcd0003d24e00257751,
        0x6ca4007352f40070792c00257281001e34690067826b003c60d000395d69,
        0x6dd5de007e8b5900762802003c817a003c600900230a4d00321fb30038b752,
        0x7fd928001d883c002894c500163712005747c9001b2a030000e70c00559189
    ];

    uint256 t = 1;
    uint256 m = n;

    uint256 S;

    assembly ("memory-safe") {
        for {} gt(m, 1) {} {
            // while(m > 1)
            let j1 := 0
            let h := shr(1, m) //uint h = m>>1;
            for { let i := 0 } gt(h, i) { i := add(i, 1) } {
                //while(m<n)
                let j2 := sub(add(j1, t), 1)
                S := mload(add(psirev, mul(32, shr(3, add(h, i)))))
                S := and(shr(mul(32, and(add(h, i), 7)), S), 0xffffffff)

                for { let j := j1 } gt(add(j2, 1), j) { j := add(j, 1) } {
                    let a_aj := add(a, mul(add(j, 1), 32)) //address of a[j]
                    let U := mload(a_aj) //U=a[j];
                    a_aj := add(a_aj, mul(t, 32)) //address of a[j+t]
                    let V := mload(a_aj)
                    mstore(a_aj, mulmod(addmod(U, sub(q, V), q), S, q)) //a[j+t]=mulmod(addmod(U,q-V,q),S[0],q);
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

