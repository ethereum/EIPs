// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

library AddressUtil {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

abstract contract MultiOwnable is Ownable {
    mapping(address => bool) private _admins;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() Ownable() {
        _admins[_msgSender()] = true;
    }

    function addAdmin(address newAdmin) public onlyOwner {
        _admins[newAdmin] = true;
    }

    function revokeAdmin(address currentAdmin) public onlyOwner {
        delete _admins[currentAdmin];
    }

    function isAdmin(address sender) public view returns(bool) {
        return _admins[sender];
    }

    /**
     * @dev Throws if called by a non-admin
     */
    modifier onlyAdmins() {
        require(_admins[_msgSender()] == true, "Ownable: caller is not an admin");
        _;
    }
}

interface IERC5169 {
    /// @dev This event emits when the scriptURI is updated, 
    /// so wallets implementing this interface can update a cached script
    event ScriptUpdate(string newScriptURI);

    /// @notice Get the scriptURI for the contract
    /// @return The scriptURI
    function scriptURI() external view returns(string memory);
	
    /// @notice Update the scriptURI
    /// emits event ScriptUpdate(string memory newScriptURI);
    function updateScriptURI(string memory newScriptURI) external;
}

contract STLDoor is ERC721, MultiOwnable, IERC5169 {
    using AddressUtil for address;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter public _tokenIdCounter;
    Counters.Counter public _topTokenIdCounter;
    Counters.Counter public _stlTokenIdCounter;

    uint256 private constant _topTokenId = 10000;

    string private _scriptURI;

    constructor() ERC721("STL HQ Door", "OFFICE") {
        _tokenIdCounter.increment();
        _scriptURI = "ipfs://QmXXLFBeSjXAwAhbo1344wJSjLgoUrfUK9LE57oVubaRRp"; 
        mintUsingSequentialTokenId(); 
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmUgdLvPvjuHGfMsuK1H2jFpg5r1QNc8JeWyXyRwKP8pTf";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "tokenURI: URI query for nonexistent token");
        if (tokenId < _topTokenId) { 
            return "ipfs://QmW948aN4Tjh4eLkAAo8os1AcM2FJjA46qtaEfFAnyNYzY";
        } else if (tokenId < _topTokenId * 2) {
            return "ipfs://QmR31f2AUokC5QyLXzDYUjy5tVibkjbW4voVuMBZfrNVU8";
        } else {
            return "ipfs://QmdaSTaF6WXpYWiL5ck7csmTy5EWHzYVGykJZN7TR95dSS";
        }
    }

    function scriptURI() public view override returns (string memory) {
        return _scriptURI;
    }

    function updateScriptURI(string memory newScriptURI) public override onlyAdmins {
        _scriptURI = newScriptURI;
        emit ScriptUpdate(newScriptURI);
    }
    
    function mintUsingSequentialTokenId() public onlyAdmins returns (uint256 tokenId) {
        tokenId = _tokenIdCounter.current();
        require(tokenId < _topTokenId, "Hit upper mint limit");
        _mint(msg.sender, tokenId);
        _tokenIdCounter.increment();
    }

    function topMintUsingSequentialTokenId() public onlyAdmins returns (uint256 tokenId) {
        tokenId = _topTokenIdCounter.current() + _topTokenId;
        require(tokenId < _topTokenId*2, "Hit upper mint limit");
        _mint(msg.sender, tokenId);
        _topTokenIdCounter.increment();
    }

    function stlMintUsingSequentialTokenId() public onlyAdmins returns (uint256 tokenId) {
        tokenId = _stlTokenIdCounter.current() + _topTokenId*2;
        _mint(msg.sender, tokenId);
        _stlTokenIdCounter.increment();
    }

    function burnToken(uint256 tokenId) public onlyAdmins {
        require(_exists(tokenId), "burn: nonexistent token");
        _burn(tokenId);
    }

    // Only allow owners to transfer tokens
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override onlyAdmins {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAdmins {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function selfDestruct() public payable onlyOwner {
        selfdestruct(payable(owner()));
    }
}
