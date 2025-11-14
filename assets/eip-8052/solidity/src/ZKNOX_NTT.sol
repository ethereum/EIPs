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

/// @title ZKNOX_NTT
/// @notice A contract to compute NTT and polynomial multiplications for DILITHIUM/FALCON signatures

/// @custom:experimental This library is not audited yet, do not use in production.

contract ZKNOX_NTT {
    /**
     *
     */
    /*                                                                  COMMON                                                                                              */
    /**
     *
     */

    //Vectorized modular multiplication
    //Multiply chunk wise vectors of n chunks modulo q
    function ZKNOX_VECMULMOD(uint256[] memory a, uint256[] memory b, uint256 q) public pure returns (uint256[] memory) {
        assert(a.length == b.length);
        uint256[] memory res = new uint256[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            res[i] = mulmod(a[i], b[i], q);
        }
        return res;
    }

    //Vectorized modular multiplication
    //Multiply chunk wise vectors of n chunks modulo q
    function ZKNOX_VECADDMOD(uint256[] memory a, uint256[] memory b, uint256 q) public pure returns (uint256[] memory) {
        assert(a.length == b.length);
        uint256[] memory res = new uint256[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            res[i] = addmod(a[i], b[i], q);
        }
        return res;
    }

    //Vectorized modular multiplication
    //Multiply chunk wise vectors of n chunks modulo q
    function ZKNOX_VECSUBMOD(uint256[] memory a, uint256[] memory b, uint256 q) public pure returns (uint256[] memory) {
        assert(a.length == b.length);
        uint256[] memory res = new uint256[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            res[i] = addmod(a[i], q - b[i], q);
        }
        return res;
    }

    /**
     * STATEFUL VERSION
     */
    /* STORAGE FOR THE STATEFUL VERSION */
    address public o_psirev; //external contract containing psi_rev
    address public o_psi_inv_rev; //external contract containing psi_inv_rev
    uint256 storage_q;
    uint256 storage_nm1modq; //n^-1 mod 12289
    uint256 is_immutable; //"antifuse" variable

    uint256 constant mask16 = 0xffff;
    uint256 constant chunk16Byword = 16; //number of 1§ bits chunks in a word of 256 bits

    constructor(address Apsi_rev, address Apsi_inrev, uint256 q, uint256 nm1modq) {
        storage_q = q; //prime field modulus
        storage_nm1modq = nm1modq; //n^-1 mod 12289, used in inverse NTT

        o_psirev = Apsi_rev;
        o_psi_inv_rev = Apsi_inrev;
        is_immutable = 1;
    }

    function update(address Apsi_rev, address Apsi_inrev, uint256 q, uint256 nm1modq) public {
        if (is_immutable > 0) {
            storage_q = q; //prime field modulus
            storage_nm1modq = nm1modq; //n^-1 mod 12289, used in inverse NTT

            o_psirev = Apsi_rev;
            o_psi_inv_rev = Apsi_inrev;
        }
    }

    //by calling this function, the contract storage variables cannot be modified  (precomputed values)
    function make_immutable() public {
        is_immutable = 1;
    }

    // NTT_FW as specified by EIP, statefull version
    //address apsirev: address of the contract storing the powers of psi
    function ZKNOX_NTTFW(uint256[] memory a, address apsirev) public view returns (uint256[] memory) {
        uint256 n = a.length;
        uint256 t = n;
        uint256 m = 1;
        uint256 q = storage_q;

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

    // NTT_INV as specified by EIP, stateful version
    //address apsiinvrev: address of the contract storing the powers of psi^-1
    function ZKNOX_NTTINV(uint256[] memory a, address apsiinvrev) public view returns (uint256[] memory) {
        uint256 t = 1;
        uint256 m = a.length;
        uint256 q = storage_q;
        uint256 nm1modq = storage_nm1modq;

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

    //multiply two polynomials over Zq a being in standard canonical representation, b in ntt representation with reduction polynomial X^n+1
    function ZKNOX_NTT_HALFMUL(uint256[] memory a, uint256[] memory b) public view returns (uint256[] memory) {
        return (ZKNOX_NTTINV(ZKNOX_VECMULMOD(ZKNOX_NTTFW(a, o_psirev), b, storage_q), o_psi_inv_rev));
    }

    //multiply two polynomials over Zq a being in standard canonical representation, b in ntt representation with reduction polynomial X^n+1
    function ZKNOX_NTT_MUL(uint256[] memory a, uint256[] memory b) public view returns (uint256[] memory) {
        return
            (ZKNOX_NTTINV(
                    ZKNOX_VECMULMOD(ZKNOX_NTTFW(a, o_psirev), ZKNOX_NTTFW(b, o_psirev), storage_q), o_psi_inv_rev
                ));
    }

    /**
     *
     */
    /*                                                                  STATELESS VERSION                                                                                   */
    /**
     *
     */
    /* CONSTANTS FOR THE STATELESS VERSION, falcon field by default */
    // forgefmt: disable-next-line
    uint256[512] psi_rev = [uint256(1), 10810, 7143, 4043, 10984, 722, 5736, 8155, 3542, 8785, 9744, 3621, 10643, 1212, 3195, 5860, 7468, 2639, 9664, 11340, 11726, 9314, 9283, 9545, 5728, 7698, 5023, 5828, 8961, 6512, 7311, 1351, 2319, 11119, 11334, 11499, 9088, 3014, 5086, 10963, 4846, 9542, 9154, 3712, 4805, 8736, 11227, 9995, 3091, 12208, 7969, 11289, 9326, 7393, 9238, 2366, 11112, 8034, 10654, 9521, 12149, 10436, 7678, 11563, 1260, 4388, 4632, 6534, 2426, 334, 1428, 1696, 2013, 9000, 729, 3241, 2881, 3284, 7197, 10200, 8595, 7110, 10530, 8582, 3382, 11934, 9741, 8058, 3637, 3459, 145, 6747, 9558, 8357, 7399, 6378, 9447, 480, 1022, 9, 9821, 339, 5791, 544, 10616, 4278, 6958, 7300, 8112, 8705, 1381, 9764, 11336, 8541, 827, 5767, 2476, 118, 2197, 7222, 3949, 8993, 4452, 2396, 7935, 130, 2837, 6915, 2401, 442, 7188, 11222, 390, 773, 8456, 3778, 354, 4861, 9377, 5698, 5012, 9808, 2859, 11244, 1017, 7404, 1632, 7205, 27, 9223, 8526, 10849, 1537, 242, 4714, 8146, 9611, 3704, 5019, 11744, 1002, 5011, 5088, 8005, 7313, 10682, 8509, 11414, 9852, 3646, 6022, 2987, 9723, 10102, 6250, 9867, 11224, 2143, 11885, 7644, 1168, 5277, 11082, 3248, 493, 8193, 6845, 2381, 7952, 11854, 1378, 1912, 2166, 3915, 12176, 7370, 12129, 3149, 12286, 4437, 3636, 4938, 5291, 2704, 10863, 7635, 1663, 10512, 3364, 1689, 4057, 9018, 9442, 7875, 2174, 4372, 7247, 9984, 4053, 2645, 5195, 9509, 7394, 1484, 9042, 9603, 8311, 9320, 9919, 2865, 5332, 3510, 1630, 10163, 5407, 3186, 11136, 9405, 10040, 8241, 9890, 8889, 7098, 9153, 9289, 671, 3016, 243, 6730, 420, 10111, 1544, 3985, 4905, 3531, 476, 49, 1263, 5915, 1483, 9789, 10800, 10706, 6347, 1512, 350, 10474, 5383, 5369, 10232, 9087, 4493, 9551, 6421, 6554, 2655, 9280, 1693, 174, 723, 10314, 8532, 347, 2925, 8974, 11863, 1858, 4754, 3030, 4115, 2361, 10446, 2908, 218, 3434, 8760, 3963, 576, 6142, 9842, 1954, 10238, 9407, 10484, 3991, 8320, 9522, 156, 2281, 5876, 10258, 5333, 3772, 418, 5908, 11836, 5429, 7515, 7552, 1293, 295, 6099, 5766, 652, 8273, 4077, 8527, 9370, 325, 10885, 11143, 11341, 5990, 1159, 8561, 8240, 3329, 4298, 12121, 2692, 5961, 7183, 10327, 1594, 6167, 9734, 7105, 11089, 1360, 3956, 6170, 5297, 8210, 11231, 922, 441, 1958, 4322, 1112, 2078, 4046, 709, 9139, 1319, 4240, 8719, 6224, 11454, 2459, 683, 3656, 12225, 10723, 5782, 9341, 9786, 9166, 10542, 9235, 6803, 7856, 6370, 3834, 7032, 7048, 9369, 8120, 9162, 6821, 1010, 8807, 787, 5057, 4698, 4780, 8844, 12097, 1321, 4912, 10240, 677, 6415, 6234, 8953, 1323, 9523, 12237, 3174, 1579, 11858, 9784, 5906, 3957, 9450, 151, 10162, 12231, 12048, 3532, 11286, 1956, 7280, 11404, 6281, 3477, 6608, 142, 11184, 9445, 3438, 11314, 4212, 9260, 6695, 4782, 5886, 8076, 504, 2302, 11684, 11868, 8209, 3602, 6068, 8689, 3263, 6077, 7665, 7822, 7500, 6752, 4749, 4449, 6833, 12142, 8500, 6118, 8471, 1190, 9606, 3860, 5445, 7753, 11239, 5079, 9027, 2169, 11767, 7965, 4916, 8214, 5315, 11011, 9945, 1973, 6715, 8775, 11248, 5925, 11271, 654, 3565, 1702, 1987, 6760, 5206, 3199, 12233, 6136, 6427, 6874, 8646, 4948, 6152, 400, 10561, 5339, 5446, 3710, 6093, 468, 8301, 316, 11907, 10256, 8291, 3879, 1922, 10930, 6854, 973, 11035];

    // forgefmt: disable-next-line
    uint256[512] psi_inv_rev = [uint256(1), 1479, 8246, 5146, 4134, 6553, 11567, 1305, 6429, 9094, 11077, 1646, 8668, 2545, 3504, 8747, 10938, 4978, 5777, 3328, 6461, 7266, 4591, 6561, 2744, 3006, 2975, 563, 949, 2625, 9650, 4821, 726, 4611, 1853, 140, 2768, 1635, 4255, 1177, 9923, 3051, 4896, 2963, 1000, 4320, 81, 9198, 2294, 1062, 3553, 7484, 8577, 3135, 2747, 7443, 1326, 7203, 9275, 3201, 790, 955, 1170, 9970, 5374, 9452, 12159, 4354, 9893, 7837, 3296, 8340, 5067, 10092, 12171, 9813, 6522, 11462, 3748, 953, 2525, 10908, 3584, 4177, 4989, 5331, 8011, 1673, 11745, 6498, 11950, 2468, 12280, 11267, 11809, 2842, 5911, 4890, 3932, 2731, 5542, 12144, 8830, 8652, 4231, 2548, 355, 8907, 3707, 1759, 5179, 3694, 2089, 5092, 9005, 9408, 9048, 11560, 3289, 10276, 10593, 10861, 11955, 9863, 5755, 7657, 7901, 11029, 11813, 8758, 7384, 8304, 10745, 2178, 11869, 5559, 12046, 9273, 11618, 3000, 3136, 5191, 3400, 2399, 4048, 2249, 2884, 1153, 9103, 6882, 2126, 10659, 8779, 6957, 9424, 2370, 2969, 3978, 2686, 3247, 10805, 4895, 2780, 7094, 9644, 8236, 2305, 5042, 7917, 10115, 4414, 2847, 3271, 8232, 10600, 8925, 1777, 10626, 4654, 1426, 9585, 6998, 7351, 8653, 7852, 3, 9140, 160, 4919, 113, 8374, 10123, 10377, 10911, 435, 4337, 9908, 5444, 4096, 11796, 9041, 1207, 7012, 11121, 4645, 404, 10146, 1065, 2422, 6039, 2187, 2566, 9302, 6267, 8643, 2437, 875, 3780, 1607, 4976, 4284, 7201, 7278, 11287, 545, 7270, 8585, 2678, 4143, 7575, 12047, 10752, 1440, 3763, 3066, 12262, 5084, 10657, 4885, 11272, 1045, 9430, 2481, 7277, 6591, 2912, 7428, 11935, 8511, 3833, 11516, 11899, 1067, 5101, 11847, 9888, 1254, 11316, 5435, 1359, 10367, 8410, 3998, 2033, 382, 11973, 3988, 11821, 6196, 8579, 6843, 6950, 1728, 11889, 6137, 7341, 3643, 5415, 5862, 6153, 56, 9090, 7083, 5529, 10302, 10587, 8724, 11635, 1018, 6364, 1041, 3514, 5574, 10316, 2344, 1278, 6974, 4075, 7373, 4324, 522, 10120, 3262, 7210, 1050, 4536, 6844, 8429, 2683, 11099, 3818, 6171, 3789, 147, 5456, 7840, 7540, 5537, 4789, 4467, 4624, 6212, 9026, 3600, 6221, 8687, 4080, 421, 605, 9987, 11785, 4213, 6403, 7507, 5594, 3029, 8077, 975, 8851, 2844, 1105, 12147, 5681, 8812, 6008, 885, 5009, 10333, 1003, 8757, 241, 58, 2127, 12138, 2839, 8332, 6383, 2505, 431, 10710, 9115, 52, 2766, 10966, 3336, 6055, 5874, 11612, 2049, 7377, 10968, 192, 3445, 7509, 7591, 7232, 11502, 3482, 11279, 5468, 3127, 4169, 2920, 5241, 5257, 8455, 5919, 4433, 5486, 3054, 1747, 3123, 2503, 2948, 6507, 1566, 64, 8633, 11606, 9830, 835, 6065, 3570, 8049, 10970, 3150, 11580, 8243, 10211, 11177, 7967, 10331, 11848, 11367, 1058, 4079, 6992, 6119, 8333, 10929, 1200, 5184, 2555, 6122, 10695, 1962, 5106, 6328, 9597, 168, 7991, 8960, 4049, 3728, 11130, 6299, 948, 1146, 1404, 11964, 2919, 3762, 8212, 4016, 11637, 6523, 6190, 11994, 10996, 4737, 4774, 6860, 453, 6381, 11871, 8517, 6956, 2031, 6413, 10008, 12133, 2767, 3969, 8298, 1805, 2882, 2051, 10335, 2447, 6147, 11713, 8326, 3529, 8855, 12071, 9381, 1843, 9928, 8174, 9259, 7535, 10431, 426, 3315, 9364, 11942, 3757, 1975, 11566, 12115, 10596, 3009, 9634, 5735, 5868, 2738, 7796, 3202, 2057, 6920, 6906, 1815, 11939, 10777, 5942, 1583, 1489, 2500, 10806, 6374, 11026, 12240];

    // # following eprint 2016/504 Algorithm 1
    function ZKNOX_NTTFW(uint256[] memory a, uint256 q) public view returns (uint256[] memory) {
        uint256 n = a.length;
        uint256 t = n;
        uint256 m = 1;

        while (m < n) {
            t = t >> 1;
            for (uint256 i = 0; i < m; i++) {
                uint256 j1 = (i * t) << 1;
                uint256 j2 = j1 + t - 1;
                uint256 S = psi_rev[m + i];

                for (uint256 j = j1; j < j2 + 1; j++) {
                    uint256 U = a[j];
                    uint256 V = mulmod(a[j + t], S, q);
                    a[j] = addmod(U, V, q);
                    a[j + t] = addmod(U, q - V, q); //U-V
                }
            }
            m = m << 1;
        }
        return a;
    }

    // NTT_INV as specified by EIP, stateless version
    function ZKNOX_NTTINV(uint256[] memory a, uint256 q) public view returns (uint256[] memory) {
        uint256 t = 1;
        uint256 m = a.length; //m=n

        while (m > 1) {
            uint256 j1 = 0;
            uint256 h = m >> 1;
            for (uint256 i = 0; i < h; i++) {
                uint256 j2 = j1 + t - 1;
                uint256 S = psi_inv_rev[h + i];
                for (uint256 j = j1; j < j2 + 1; j++) {
                    uint256 U = a[j];
                    uint256 V = a[j + t];
                    a[j] = addmod(U, V, q);
                    a[j + t] = mulmod(addmod(U, q - V, q), S, q);
                } //end loop j
                j1 = j1 + (t << 1);
            } //end loop i
            t = (t << 1);
            m = m >> 1;
        } //end while

        t = storage_nm1modq; //sparing one variable for stack
        for (m = 0; m < a.length; m++) {
            a[m] = mulmod(a[m], t, q);
        }

        return a;
    }

    //multiply two polynomials over Zq in standard canonical representation with reduction polynomial X^n+1
    function mul_NTTPoly(uint256[] memory a, uint256[] memory b, uint256 q) public view returns (uint256[] memory) {
        return ZKNOX_NTTINV(ZKNOX_VECMULMOD(ZKNOX_NTTFW(a, q), ZKNOX_NTTFW(b, q), q), q);
    }

    //multiply two polynomials over Zq a being in standard canonical representation, b in ntt representation with reduction polynomial X^n+1
    function ZKNOX_NTT_HALFMUL(uint256[] memory a, uint256[] memory b, uint256 q)
        public
        view
        returns (uint256[] memory)
    {
        return (ZKNOX_NTTINV(ZKNOX_VECMULMOD(ZKNOX_NTTFW(a, q), b, q), q));
    }

    //// WIP

    //// internal version to spare call data cost

    // NTT_FW as specified by EIP, statefull version
    //address apsirev: address of the contract storing the powers of psi
    function _ZKNOX_NTTFW(uint256[] memory a, address apsirev) public view returns (uint256[] memory) {
        uint256 n = a.length;
        uint256 t = n;
        uint256 m = 1;
        uint256 q = storage_q;

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

    // NTT_INV as specified by EIP, stateful version
    //address apsiinvrev: address of the contract storing the powers of psi^-1
    function _ZKNOX_NTTINV(uint256[] memory a, address apsiinvrev) public view returns (uint256[] memory) {
        uint256 t = 1;
        uint256 m = a.length;
        uint256 q = storage_q;
        uint256 nm1modq = storage_nm1modq;

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

    function ZKNOX_NTT_Expand(uint256[] memory a) internal pure returns (uint256[] memory b) {
        b = new uint256[](512);
        /*
        for (uint256 i = 0; i < 32; i++) {
            uint256 ai = a[i];
            for (uint256 j = 0; j < 16; j++) {
                b[(i << 4) + j] = (ai >> (j << 4)) & mask16;
            }
        }*/

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

    function ZKNOX_NTT_Compact(uint256[] memory a) internal pure returns (uint256[] memory b) {
        b = new uint256[](32);

        /*
        for (uint256 i = 0; i < a.length; i++) {
            b[i >> 4] ^= a[i] << ((i & 0xf) << 4);
        }*/

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
    //Vectorized modular multiplication
    //Multiply chunk wise vectors of n chunks modulo q

    function _ZKNOX_VECMULMOD(uint256[] memory a, uint256[] memory b, uint256 q)
        public
        pure
        returns (uint256[] memory)
    {
        assert(a.length == b.length);
        uint256[] memory res = new uint256[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            res[i] = mulmod(a[i], b[i], q);
        }
        return res;
    }

    //multiply two polynomials over Zq a being in standard canonical representation, b in ntt representation with reduction polynomial X^n+1
    //packed input and output (16 chunks by word)
    function ZKNOX_NTT_HALFMUL_Compact(uint256[] memory a, uint256[] memory b) public view returns (uint256[] memory) {
        return (ZKNOX_NTT_Compact(
                _ZKNOX_NTTINV(
                    _ZKNOX_VECMULMOD(_ZKNOX_NTTFW(ZKNOX_NTT_Expand(a), o_psirev), ZKNOX_NTT_Expand(b), storage_q),
                    o_psi_inv_rev
                )
            ));
    }
} //end of contract
/**
 *
 */
/*                                                                  END OF CONTRACT                                                                                     */
/**
 *
 */
