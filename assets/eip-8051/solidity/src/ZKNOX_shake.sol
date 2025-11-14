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
///* FILE: ZKNOX_falcon.sol
///* Description: shake XOF function implementation
/**
 *
 */
// SPDX-License-Identifier: MIT
//this is a direct translation from https://github.com/coruus/py-keccak/blob/master/fips202/keccak.py
pragma solidity ^0.8.25;

uint256 constant _RATE = 136;
bool constant _SPONGE_ABSORBING = false;
bool constant _SPONGE_SQUEEZING = true;

struct ctx_shake {
    uint64[25] state;
    uint8[200] buff;
    uint256 i;
    bool direction;
}

// """Rotate uint64 x left by s.""
function rol64(uint256 x, uint256 s) pure returns (uint64) {
    return (uint64)((x << s) ^ (x >> (64 - s)));
}

function F1600(uint64[25] memory state) pure returns (uint64[25] memory) {
    // forgefmt: disable-next-line
    uint256[24] memory _KECCAK_PI = [uint256(10), 7, 11, 17, 18, 3, 5, 16, 8, 21, 24, 4, 15, 23, 19, 13, 12, 2, 20, 14, 22, 9, 6, 1];// forgefmt: disable-next-line
    uint64[24] memory _KECCAK_RC = [uint64(0x0000000000000001), 0x0000000000008082,0x800000000000808a,0x8000000080008000,0x000000000000808b, 0x0000000080000001,0x8000000080008081, 0x8000000000008009,0x000000000000008a, 0x0000000000000088,0x0000000080008009, 0x000000008000000a,0x000000008000808b, 0x800000000000008b,0x8000000000008089, 0x8000000000008003,0x8000000000008002, 0x8000000000000080,0x000000000000800a, 0x800000008000000a,0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008];// forgefmt: disable-next-line
    uint256[24] memory _KECCAK_RHO =[uint256(1), 3, 6, 10, 15, 21, 28, 36, 45, 55, 2, 14, 27, 41, 56, 8, 25, 43, 62, 18, 39, 61, 20, 44];

    uint64[5] memory bc = [uint64(0), 0, 0, 0, 0];

    assembly {
        for { let i := 0 } gt(24, i) { i := add(i, 1) } {
            //
            let t
            let offset_X
            for { offset_X := 0 } gt(160, offset_X) { offset_X := add(offset_X, 32) } {
                //for (uint256 x = 0; x < 5; x++)
                mstore(add(bc, offset_X), 0) //bc[x] = 0;

                let bcx := add(bc, offset_X)
                let temp := mload(bcx)
                for { let offset_Y := 0 } gt(800, offset_Y) { offset_Y := add(offset_Y, 160) } {
                    temp := xor(temp, mload(add(state, add(offset_X, offset_Y)))) // bc[x] ^= state[x + y];
                }
                mstore(bcx, temp)
            }

            //# Theta
            // for (uint256 x = 0; x < 5; x++) {
            for { let x := 0 } gt(160, x) { x := add(32, x) } {
                //t = bc[addmod(x, 4, 5)] ^ rol64(bc[addmod(x, 1, 5)], 1);
                let temp := mload(add(bc, addmod(x, 32, 160)))
                t := and(0xffffffffffffffff, xor(shl(1, temp), shr(63, temp))) //rol64(bc[addmod(x, 1, 5)], 1);
                t := xor(t, mload(add(bc, addmod(x, 128, 160)))) //beware of and

                /*
                for (uint64 y = 0; y < 25; y += 5) {
                    // in range(0, 25, 5):
                    state[y + x] ^= t;
                }*/

                let endloop := add(add(state, x), 800)
                for { let offset := add(state, x) } gt(endloop, offset) { offset := add(offset, 160) } {
                    mstore(offset, xor(mload(offset), t))
                }
            }
            t := mload(add(state, 32)) //t=state[1]

            for { let x := 0 } gt(768, x) { x := add(x, 32) } {
                //x in [0..23]
                //  for (uint256 x = 0; x < 24; x++) {
                let keccakpix := mload(add(_KECCAK_PI, x)) //_KECCAK_PI[x]
                let kpix := add(state, shl(5, keccakpix)) //@_KECCAK_PI[x];
                mstore(bc, mload(kpix)) //bc[0] = state[keccakpix];
                let res := mload(add(x, _KECCAK_RHO)) // _KECCAK_RHO[x]
                res := and(0xffffffffffffffff, xor(shl(res, t), shr(sub(64, res), t))) //rol64(t, _KECCAK_RHO[x]);

                mstore(kpix, res) //state[keccakpix] = uint64(res);//rol64(t,res);//rol64(t, _KECCAK_RHO[x]);
                t := mload(bc) // t = bc[0];
            }

            for { let y := 0 } gt(800, y) { y := add(y, 160) } {
                // for (uint256 y = 0; y < 25; y += 5) {
                for { offset_X := 0 } gt(160, offset_X) { offset_X := add(offset_X, 32) } {
                    //for (uint256 x = 0; x < 5; x++) {
                    mstore(add(bc, offset_X), mload(add(state, add(offset_X, y)))) //  bc[x] = state[y + x];
                }

                let offset_Y := add(state, y)

                for { offset_X := 0 } gt(160, offset_X) { offset_X := add(offset_X, 32) } {
                    let offset := add(offset_X, offset_Y) //address of state[x+y]

                    mstore(
                        offset,
                        xor(
                            mload(add(offset_X, bc)),
                            and(
                                xor(mload(add(bc, addmod(offset_X, 32, 160))), 0xffffffffffffffff),
                                mload(add(bc, addmod(offset_X, 64, 160)))
                            )
                        )
                    )
                }

                mstore(state, and(xor(mload(state), mload(add(_KECCAK_RC, shl(5, i)))), 0xffffffffffffffff)) //state[0] ^= _KECCAK_RC[i];
            } //end loop y

        } //end loop i

    }
    return state;
} //end F1600

function shake_absorb(uint256 i, uint8[200] memory buf, uint64[25] memory state, bytes memory input)
    pure
    returns (uint256 iout, uint8[200] memory bufout, uint64[25] memory stateout)
{
    uint256 todo = input.length;

    uint256 index = 0;
    while (todo > 0) {
        uint256 cando = _RATE - i;
        uint256 willabsorb = (cando < todo) ? cando : todo;

        for (uint256 j = 0; j < willabsorb; j++) {
            buf[i + j] ^= uint8(input[index + j]);
        }
        i += willabsorb;

        if (i == _RATE) {
            (buf, state) = shake_permute(buf, state);
            i = 0;
        }
        todo -= willabsorb;
        index += willabsorb;
    }
    return (i, buf, state);
}

//can be ignored, as it is a zeroized structure
function shake_init() pure returns (ctx_shake memory ctx) {
    // forgefmt: disable-next-line
        ctx.state=[uint64(0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];// forgefmt: disable-next-line
        ctx.buff=[uint8(0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,uint8(0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,uint8(0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,uint8(0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,uint8(0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,uint8(0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,uint8(0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,uint8(0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    ctx.direction = _SPONGE_ABSORBING;

    return ctx;
}

function shake_update(ctx_shake memory ctx, bytes memory input) pure returns (ctx_shake memory ctxout) {
    if (ctx.direction == _SPONGE_SQUEEZING) {
        (ctx.buff, ctx.state) = shake_permute(ctx.buff, ctx.state);
    }
    ctxout.direction = _SPONGE_ABSORBING;
    (ctxout.i, ctxout.buff, ctxout.state) = shake_absorb(ctx.i, ctx.buff, ctx.state, input);
    return ctxout;
}

function shake_squeeze(ctx_shake memory ctx, uint256 n) pure returns (ctx_shake memory ctxout, bytes memory) {
    bytes memory output = new bytes(n);
    uint256 tosqueeze = n;
    uint256 offset = 0;

    while (tosqueeze > 0) {
        uint256 cansqueeze = _RATE - ctx.i;
        uint256 willsqueeze = (cansqueeze < tosqueeze) ? cansqueeze : tosqueeze;

        for (uint256 j = 0; j < willsqueeze; j++) {
            uint256 read = ctx.i + j;

            output[offset + j] = bytes1(uint8((ctx.state[(read >> 3)] >> ((read & 7) << 3)) & 0xff));
        }
        offset += willsqueeze;
        ctx.i += willsqueeze;
        if (ctx.i == _RATE) {
            (ctx.buff, ctx.state) = shake_permute(ctx.buff, ctx.state);
            ctx.i = 0;
        }
        tosqueeze -= willsqueeze;
    }

    return (ctx, output);
}

function shake_permute(uint8[200] memory buf, uint64[25] memory state)
    pure
    returns (uint8[200] memory buffer, uint64[25] memory stateout)
{
    //require a 64 bits swap
    /*for (uint256 j = 0; j < 200; j++) {
        state[j / 8] ^= uint64(buf[j]) << (((uint8(j & 0x7) << 3)));
    }*/

    assembly {
        for { let j := 0 } gt(200, j) { j := add(j, 1) } {
            let addr := add(state, shl(5, shr(3, j))) //state[j / 8]
            let val := shl(shl(3, and(j, 7)), and(0xffffffffffffffff, mload(add(buf, shl(5, j))))) // uint64(buf[j]) << (((uint8(j & 0x7) << 3)));

            mstore(addr, xor(mload(addr), val))
        }
    }

    // Call F1600 Keccak permutation function here
    state = F1600(state);
    //directly return buffer: it is zeroized by default
    return (buffer, state); //zeroization of buf external to this function
}

function shake_pad(ctx_shake memory ctx) pure returns (ctx_shake memory ctxout) {
    ctx.buff[ctx.i] ^= 0x1f;
    ctx.buff[_RATE - 1] ^= 0x80;
    (ctx.buff, ctx.state) = shake_permute(ctx.buff, ctx.state);

    ctx.i = 0;

    return ctx;
}

function shake_digest(ctx_shake memory ctx, uint256 size8) pure returns (bytes memory output) {
    output = new bytes(size8);
    if (ctx.direction == _SPONGE_ABSORBING) {
        ctx.buff[ctx.i] ^= 0x1f;
        ctx.buff[_RATE - 1] ^= 0x80;
        (ctx.buff, ctx.state) = shake_permute(ctx.buff, ctx.state);

        ctx.i = 0;
    }
    //display_state(ctx.state);
    (, output) = shake_squeeze(ctx, size8);
}
