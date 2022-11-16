// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./ERC721Bound.sol";
import "./IERC5058Factory.sol";

contract ERC5058Factory is IERC5058Factory {
    address[] private _allBounds;

    // Mapping from preimage to bound
    mapping(address => address) private _bounds;

    function allBoundsLength() public view virtual override returns (uint256) {
        return _allBounds.length;
    }

    function boundByIndex(uint256 index) public view virtual override returns (address) {
        require(index < _allBounds.length, "ERC5058Factory: index out of bounds");

        return _allBounds[index];
    }

    function existBound(address preimage) public view virtual override returns (bool) {
        return _bounds[preimage] != address(0);
    }

    function boundOf(address preimage) public view virtual override returns (address) {
        require(existBound(preimage), "ERC5058Factory: query for nonexistent bound");
        return _bounds[preimage];
    }

    function boundDeploy(address preimage) public virtual override returns (address) {
        require(!existBound(preimage), "ERC5058Factory: bound nft is already deployed");

        return _deploy(preimage, keccak256(abi.encode(preimage)), "Bound");
    }

    function _deploy(
        address preimage,
        bytes32 salt,
        bytes memory prefix
    ) internal returns (address) {
        IERC721Metadata collection = IERC721Metadata(preimage);
        bytes memory code = type(ERC721Bound).creationCode;
        bytes memory bytecode = abi.encodePacked(
            code,
            abi.encode(
                preimage,
                abi.encodePacked(prefix, " ", collection.name()),
                abi.encodePacked(prefix, collection.symbol())
            )
        );

        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        emit DeployedBound(preimage, addr);

        _bounds[preimage] = addr;
        _allBounds.push(addr);

        return addr;
    }
}
