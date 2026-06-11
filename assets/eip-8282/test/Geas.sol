// SPDX-License-Identifier: CC0-1.0
// FFI wrapper for the geas assembler, after the geas-ffi harness that
// ethereum/sys-asm's own test suite uses (minus the forge-std dependency).
pragma solidity ^0.8.13;

interface GeasVm {
    function ffi(string[] calldata) external returns (bytes memory);
}

library Geas {
    GeasVm private constant vm = GeasVm(address(uint160(uint256(keccak256("hevm cheat code")))));

    // compile assembles the geas source at `path` (relative to the project
    // root) and returns the bytecode. Requires `geas` on PATH and `ffi = true`.
    function compile(string memory path) internal returns (bytes memory) {
        string[] memory args = new string[](3);
        args[0] = "geas";
        args[1] = "-no-nl";
        args[2] = path;

        return vm.ffi(args);
    }
}
