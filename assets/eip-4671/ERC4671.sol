// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./IERC4671.sol";
import "./IERC4671Metadata.sol";
import "./IERC4671Enumerable.sol";

abstract contract ERC4671 is IERC4671, IERC4671Metadata, IERC4671Enumerable, ERC165 {
    // Badge data
    struct Badge {
        address issuer;
        address owner;
        bool valid;
    }

    // Mapping from badgeId to badge
    mapping(uint256 => Badge) private _badges;

    // Mapping from owner to badge ids
    mapping(address => uint256[]) private _indexedBadgeIds;

    // Mapping from owner to number of valid badges
    mapping(address => uint256) private _numberOfValidBadges;

    // Badge name
    string private _name;

    // Badge symbol
    string private _symbol;

    // Total number of badges emitted
    uint256 private _total;

    // Contract creator
    address private _creator;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _creator = msg.sender;
    }

    /// @notice Count all badges assigned to an owner
    /// @param owner Address for whom to query the balance
    /// @return Number of badges owned by `owner`
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return _indexedBadgeIds[owner].length;
    }

    /// @notice Get owner of a badge
    /// @param badgeId Identifier of the badge
    /// @return Address of the owner of `badgeId`
    function ownerOf(uint256 badgeId) public view virtual override returns (address) {
        return _getBadgeOrRevert(badgeId).owner;
    }

    /// @notice Check if a badge hasn't been invalidated
    /// @param badgeId Identifier of the badge
    /// @return True if the badge is valid, false otherwise
    function isValid(uint256 badgeId) public view virtual override returns (bool) {
        return _getBadgeOrRevert(badgeId).valid;
    }

    /// @notice Check if an address owns a valid badge in the contract
    /// @param owner Address for whom to check the ownership
    /// @return True if `owner` has a valid badge, false otherwise
    function hasValid(address owner) public view virtual override returns (bool) {
        return _numberOfValidBadges[owner] > 0;
    }

    /// @return Descriptive name of the badges in this contract
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @return An abbreviated name of the badges in this contract
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /// @notice URI to query to get the badge's metadata
    /// @param badgeId Identifier of the badge
    /// @return URI for the badge
    function badgeURI(uint256 badgeId) public view virtual override returns (string memory) {
        _getBadgeOrRevert(badgeId);
        bytes memory baseURI = bytes(_baseURI());
        if (baseURI.length > 0) {
            return string(abi.encodePacked(
                baseURI,
                Strings.toHexString(badgeId, 32)
            ));
        }
        return "";
    }

    /// @return Total number of badges emitted by the contract
    function total() public view override returns (uint256) {
        return _total;
    }

    /// @notice Get the badgeId of a badge using its position in the owner's list
    /// @param owner Address for whom to get the badge
    /// @param index Index of the badge
    /// @return badgeId of the badge
    function badgeOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        uint256[] storage ids = _indexedBadgeIds[owner];
        require(index < ids.length, "Badge does not exist");
        return ids[index];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return 
            interfaceId == type(IERC4671).interfaceId ||
            interfaceId == type(IERC4671Metadata).interfaceId ||
            interfaceId == type(IERC4671Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Prefix for all calls to badgeURI
    /// @return Common base URI for all badge
    function _baseURI() internal pure virtual returns (string memory) {
        return "";
    }

    /// @notice Mark the badge as invalidated
    /// @param badgeId Identifier of the badge
    function _invalidate(uint256 badgeId) internal virtual {
        Badge storage badge = _getBadgeOrRevert(badgeId);
        require(badge.valid, "Badge is already invalid");
        badge.valid = false;
        _numberOfValidBadges[badge.owner] -= 1;
        assert(_numberOfValidBadges[badge.owner] >= 0);
        emit Invalidated(badge.owner, badgeId);
    }

    /// @notice Mint a new badge
    /// @param owner Address for whom to assign the badge
    /// @return badgeId Identifier of the minted badge
    function _mint(address owner) internal virtual returns (uint256 badgeId) {
        badgeId = _total;
        _badges[badgeId] = Badge(msg.sender, owner, true);
        _indexedBadgeIds[owner].push(badgeId);
        _numberOfValidBadges[owner] += 1;
        _total += 1;
        emit Minted(owner, badgeId);
    }

    /// @return True if the caller is the contract's creator, false otherwise
    function _isCreator() internal view virtual returns (bool) {
        return msg.sender == _creator;
    }

    /// @notice Retrieve a Badge or revert if it does not exist
    /// @param badgeId Identifier of the badge
    /// @return The Badge struct
    function _getBadgeOrRevert(uint256 badgeId) internal view virtual returns (Badge storage) {
        Badge storage badge = _badges[badgeId];
        require(badge.owner != address(0), "Badge does not exist");
        return badge;
    }
}