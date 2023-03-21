// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC4365/IERC4365.sol";
import "../token/ERC4365/extensions/ERC4365Expirable.sol";

contract Ticket is ERC4365, ERC4365Expirable {
    using Address for address;

    address public owner;

    constructor(address owner_, string memory baseURI_) ERC4365(baseURI_) {
        owner = owner_;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized: sender is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address for new owner");
        owner = newOwner;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _setBaseURI(newBaseURI);
    }

    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external onlyOwner {
        _mint(to, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes calldata data) 
        external 
        onlyOwner 
    {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(address from, uint256 id, uint256 amount) external {
        require(msg.sender == from || msg.sender == owner, "Sender is not token holder or contract owner");

        _burn(from, id, amount);
    }

    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external {
         require(msg.sender == from || msg.sender == owner, "Sender is not token holder or contract owner");

         _burnBatch(from, ids, amounts);
    }

    function _setExpiryDate(uint256 id, uint256 date) internal override onlyOwner {
        super._setExpiryDate(id, date);
    }
}