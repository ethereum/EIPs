// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library CInt64 {
    /**
     * CInt Core
     */

    function compress(uint256 full) public pure returns (uint64 cint) {
        uint8 bits = mostSignificantBitPosition(full);
        if (bits <= 55) {
            cint = uint64(full) << 8;
        } else {
            bits -= 55;
            cint = (uint64(full >> bits) << 8) + bits;
        }
    }

    function decompress(uint64 cint) public pure returns (uint256 full) {
        uint8 bits = uint8(cint % (1 << 9));
        full = uint256(cint >> 8) << bits;
    }

    function decompressRoundingUp(uint64 cint)
        public
        pure
        returns (uint256 full)
    {
        uint8 bits = uint8(cint % (1 << 9));
        full = (uint256(cint >> 8) << bits) + ((1 << bits) - 1);
    }

    function mostSignificantBitPosition(uint256 val)
        public
        pure
        returns (uint8 bit)
    {
        if (val >= 0x100000000000000000000000000000000) {
            val >>= 128;
            bit += 128;
        }
        if (val >= 0x10000000000000000) {
            val >>= 64;
            bit += 64;
        }
        if (val >= 0x100000000) {
            val >>= 32;
            bit += 32;
        }
        if (val >= 0x10000) {
            val >>= 16;
            bit += 16;
        }
        if (val >= 0x100) {
            val >>= 8;
            bit += 8;
        }
        if (val >= 0x10) {
            val >>= 4;
            bit += 4;
        }
        if (val >= 0x4) {
            val >>= 2;
            bit += 2;
        }
        if (val >= 0x2) bit += 1;
    }

    /**
     * CInt Math
     */

    function cadd(uint64 a, uint64 b) public pure returns (uint64 cint) {
        cint = compress(decompress(a) + decompress(b));
    }

    function cadd(uint64 a, uint256 b) public pure returns (uint64 cint) {
        cint = compress(decompress(a) + b);
    }

    function csub(uint64 a, uint64 b) public pure returns (uint64 cint) {
        cint = compress(decompress(a) - decompress(b));
    }

    function csub(uint64 a, uint256 b) public pure returns (uint64 cint) {
        cint = compress(decompress(a) - b);
    }

    function cmul(uint64 a, uint256 b) public pure returns (uint64 cint) {
        cint = compress(decompress(a) * b);
    }

    function cdiv(uint64 a, uint256 b) public pure returns (uint64 cint) {
        cint = compress(decompress(a) / b);
    }

    function cmuldiv(
        uint64 a,
        uint64 b,
        uint64 c
    ) public pure returns (uint64 cint) {
        cint = compress((decompress(a) * decompress(b)) / decompress(c));
    }
}

contract Example {
    using CInt64 for uint64;
    using CInt64 for uint256;

    struct Slot {
        uint32 blockNumber;
        address payable receiver;
        uint64 amount;
    }

    Slot public slot;

    function deposit(uint32 blockNumber, address payable receiver)
        external
        payable
    {
        Slot memory _slot = slot; // SLOAD

        require(_slot.amount == 0, "already initialized");

        _slot.blockNumber = blockNumber;
        _slot.receiver = receiver;
        _slot.amount = msg.value.compress(); // compress with 56 most significant bits

        slot = _slot; // SSTORE
    }

    function withdraw() external {
        Slot memory _slot = slot; // SLOAD

        require(msg.sender == address(_slot.receiver), "not authorised");
        require(block.number > _slot.blockNumber, "not yet");

        _slot.receiver.transfer(slot.amount.decompress()); // transfer the less amount to user
    }
}
