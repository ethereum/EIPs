//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../ERC3525/ERC3525.sol";
import "../ERC5192/interfaces/IERC5192.sol";
import "./interfaces/IERC5727Metadata.sol";
import "./interfaces/IERC5727Enumerable.sol";

contract ERC5727 is EIP712, Ownable, ERC3525, IERC5727Metadata {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using ECDSA for bytes32;

    mapping(uint256 => address) internal _issuers;
    mapping(uint256 => address) internal _verifiers;
    mapping(uint256 => BurnAuth) internal _burnAuths;
    mapping(uint256 => bool) internal _unlocked;

    mapping(uint256 => address) internal _slotVerifiers;
    mapping(uint256 => BurnAuth) internal _slotBurnAuths;

    mapping(uint256 => mapping(address => bool)) internal _minterRole;
    mapping(uint256 => mapping(address => bool)) internal _burnerRole;

    bytes32 private constant _TOKEN_TYPEHASH =
        keccak256(
            "Token(uint256 tokenId,address owner,uint256 value,uint256 slot,address issuer,address verifier,BurnAuth burnAuth)"
        );

    modifier onlyAdmin() {
        if (owner() != _msgSender()) revert Unauthorized(_msgSender());
        _;
    }

    modifier onlyMinter(uint256 slot) {
        if (!_checkMintAuth(_msgSender(), slot))
            revert Unauthorized(_msgSender());
        _;
    }

    modifier onlyBurner(uint256 tokenId) {
        if (!_checkBurnAuth(_msgSender(), tokenId))
            revert Unauthorized(_msgSender());
        _;
    }

    modifier onlyIssuer(uint256 tokenId) {
        if (_msgSender() != _issuers[tokenId])
            revert Unauthorized(_msgSender());
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address admin_,
        string memory version_
    ) ERC3525(name_, symbol_, 18) EIP712(name_, version_) Ownable() {
        transferOwnership(admin_);
    }

    function verifierOf(
        uint256 tokenId
    ) public view virtual override returns (address) {
        address verifier = _verifiers[tokenId];
        if (verifier == address(0)) revert NotFound(tokenId);

        return verifier;
    }

    function issuerOf(
        uint256 tokenId
    ) public view virtual override returns (address) {
        address issuer = _issuers[tokenId];
        if (issuer == address(0)) revert NotFound(tokenId);

        return issuer;
    }

    function issue(
        address to,
        uint256 tokenId,
        uint256 slot,
        BurnAuth auth,
        address verifier,
        bytes calldata data
    ) public payable virtual override onlyMinter(slot) {
        if (tokenId == 0 || slot == 0 || to == address(0)) revert NullValue();

        _issue(_msgSender(), to, tokenId, slot, auth, verifier);

        data;
    }

    function issue(
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) public payable virtual override onlyIssuer(tokenId) {
        _requireMinted(tokenId);

        _issue(_msgSender(), tokenId, amount);

        data;
    }

    function _issue(
        address from,
        address to,
        uint256 tokenId,
        uint256 slot,
        BurnAuth auth,
        address verifier
    ) internal virtual {
        _mint(to, tokenId, slot);

        _issuers[tokenId] = from;
        _burnAuths[tokenId] = auth;
        _verifiers[tokenId] = verifier;

        if (auth == BurnAuth.IssuerOnly || auth == BurnAuth.Both) {
            _burnerRole[tokenId][from] = true;
            _approve(from, tokenId);
        }
        if (auth == BurnAuth.OwnerOnly || auth == BurnAuth.Both) {
            _burnerRole[tokenId][to] = true;
        }

        emit Issued(from, to, tokenId, auth);
        emit Locked(tokenId);

        _beforeValueTransfer(address(0), to, 0, tokenId, slot, 0);
        _afterValueTransfer(address(0), to, 0, tokenId, slot, 0);
    }

    function _issue(
        address from,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        _mint(tokenId, amount);

        BurnAuth auth = _burnAuths[tokenId];

        if (auth == BurnAuth.IssuerOnly || auth == BurnAuth.Both) {
            _approve(tokenId, from, amount);
        }
    }

    function revoke(
        uint256 tokenId,
        bytes calldata data
    ) public payable virtual override onlyBurner(tokenId) {
        _requireMinted(tokenId);

        _revoke(_msgSender(), tokenId);

        data;
    }

    function revoke(
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) public payable virtual override onlyBurner(tokenId) {
        _requireMinted(tokenId);

        _revoke(_msgSender(), tokenId, amount);

        data;
    }

    function locked(
        uint256 tokenId
    ) public view virtual override returns (bool) {
        _requireMinted(tokenId);

        return !_unlocked[tokenId];
    }

    function burnAuth(
        uint256 tokenId
    ) public view virtual override returns (BurnAuth) {
        _requireMinted(tokenId);

        return _burnAuths[tokenId];
    }

    function _checkBurnAuth(
        address from,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        return _burnerRole[tokenId][from];
    }

    function _checkMintAuth(
        address from,
        uint256 slot
    ) internal view virtual returns (bool) {
        return owner() == from || _minterRole[slot][from];
    }

    function hasMintRole(
        address from,
        uint256 tokenId
    ) external view virtual returns (bool) {
        return _minterRole[tokenId][from];
    }

    function hasBurnRole(
        address from,
        uint256 tokenId
    ) external view virtual returns (bool) {
        return _burnerRole[tokenId][from];
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        delete _issuers[tokenId];
        delete _verifiers[tokenId];
        delete _burnAuths[tokenId];
    }

    function _revoke(address from, uint256 tokenId) internal virtual {
        _burn(tokenId);

        emit Revoked(from, tokenId);
    }

    function _revoke(
        address from,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        _burn(tokenId, amount);

        from;
    }

    function verify(
        uint256 tokenId,
        bytes calldata data
    ) public virtual override returns (bool result) {
        _requireMinted(tokenId);

        // TODO: use actual verifier
        result = _verify(_msgSender(), tokenId, data);

        data;
    }

    function _verify(
        address by,
        uint256 tokenId,
        bytes memory data
    ) internal virtual returns (bool result) {
        bytes memory signature = abi.decode(data, (bytes));
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _TOKEN_TYPEHASH,
                    tokenId,
                    ownerOf(tokenId),
                    balanceOf(tokenId),
                    slotOf(tokenId),
                    issuerOf(tokenId),
                    verifierOf(tokenId),
                    burnAuth(tokenId)
                )
            )
        );

        address issuer = _issuers[tokenId];
        result = digest.recover(signature) == issuer;

        emit Verified(by, tokenId, result);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        if (from != address(0) && to != address(0) && !_unlocked[firstTokenId])
            revert Soulbound();

        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _beforeValueTransfer(
        address from,
        address to,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 slot,
        uint256 value
    ) internal virtual override {
        if (from != address(0) && to != address(0)) revert Soulbound();

        super._beforeValueTransfer(
            from,
            to,
            fromTokenId,
            toTokenId,
            slot,
            value
        );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC3525) returns (bool) {
        return
            interfaceId == type(IERC5727).interfaceId ||
            interfaceId == type(IERC5727Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
