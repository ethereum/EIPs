// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./ERC4671.sol";
import "./IERC4671Delegate.sol";

abstract contract ERC4671Delegate is ERC4671, IERC4671Delegate {
    // Mapping from operator to list of owners
    mapping (address => mapping(address => bool)) _allowed;

    /// @notice Grant one-time minting right to `operator` for `owner`
    /// An allowed operator can call the function to transfer rights.
    /// @param operator Address allowed to mint a token
    /// @param owner Address for whom `operator` is allowed to mint a token
    function delegate(address operator, address owner) public virtual override {
        _delegateAsDelegateOrCreator(operator, owner, _isCreator());
    }

    /// @notice Grant one-time minting right to a list of `operators` for a corresponding list of `owners`
    /// An allowed operator can call the function to transfer rights.
    /// @param operators Addresses allowed to mint a token
    /// @param owners Addresses for whom `operators` are allowed to mint a token
    function delegateBatch(address[] memory operators, address[] memory owners) public virtual override {
        require(operators.length == owners.length, "operators and owners must have the same length");
        bool isCreator = _isCreator();
        for (uint i=0; i<operators.length; i++) {
            _delegateAsDelegateOrCreator(operators[i], owners[i], isCreator);
        }
    }

    /// @notice Mint a token. Caller must have the right to mint for the owner.
    /// @param owner Address for whom the token is minted
    function mint(address owner) public virtual override {
        _mintAsDelegateOrCreator(owner, _isCreator());
    }

    /// @notice Mint tokens to multiple addresses. Caller must have the right to mint for all owners.
    /// @param owners Addresses for whom the tokens are minted
    function mintBatch(address[] memory owners) public virtual override {
        bool isCreator = _isCreator();
        for (uint i=0 ; i<owners.length; i++) {
            _mintAsDelegateOrCreator(owners[i], isCreator);
        }
    }

    /// @notice Get the issuer of a token
    /// @param tokenId Identifier of the token
    /// @return Address who minted `tokenId`
    function issuerOf(uint256 tokenId) public view virtual override returns (address) {
        return _getTokenOrRevert(tokenId).issuer;
    }

    /// @notice Check if an operator is a delegate for a given address
    /// @param operator Address of the operator
    /// @param owner Address of the token's owner
    /// @return True if the `operator` is a delegate for `owner`, false otherwise
    function isDelegate(address operator, address owner) public view virtual returns (bool) {
        return _allowed[operator][owner];
    }

    /// @notice Check if you are a delegate for a given address
    /// @param owner Address of the token's owner
    /// @return True if the caller is a delegate for `owner`, false otherwise
    function isDelegateOf(address owner) public view virtual returns (bool) {
        return isDelegate(msg.sender, owner);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC4671) returns (bool) {
        return 
            interfaceId == type(IERC4671Delegate).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _delegateAsDelegateOrCreator(address operator, address owner, bool isCreator) private {
        require(
            isCreator || _allowed[msg.sender][owner],
            "Only contract creator or allowed operator can delegate"
        );
        if (!isCreator) {
            _allowed[msg.sender][owner] = false;
        }
        _allowed[operator][owner] = true;
    }

    function _mintAsDelegateOrCreator(address owner, bool isCreator) private {
        require(
            isCreator || _allowed[msg.sender][owner],
            "Only contract creator or allowed operator can mint"
        );
        if (!isCreator) {
            _allowed[msg.sender][owner] = false;
        }
        _mint(owner);
    }
}
