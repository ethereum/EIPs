//SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC3525.sol";
import "./IERC3525Receiver.sol";
import "./extensions/IERC3525Metadata.sol";
import "./openzeppelin/ContextUpgradeable.sol";
import "./openzeppelin/ERC165Upgradeable.sol";
import "./openzeppelin/IERC721Enumerable.sol";
import "./openzeppelin/IERC721Metadata.sol";
import "./openzeppelin/IERC721Receiver.sol";
import "./utils/base64.sol";
import "./utils/StringConvertor.sol";
import "hardhat/console.sol";

abstract contract ERC3525Upgradeable is
    IERC3525Metadata,
    IERC721Enumerable,
    ERC165Upgradeable,
    ContextUpgradeable
{
    using StringConvertor for uint256;
    using AddressUpgradeable for address;

    struct TokenData {
        uint256 id;
        uint256 slot;
        uint256 balance;
        address owner;
        address approved;
        address[] valueApprovals;
    }

    struct AddressData {
        uint256[] ownedTokens;
        mapping(uint256 => uint256) ownedTokensIndex;
        mapping(address => bool) approvals;
    }

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    // id => (approval => allowance)
    // @dev _approvedValues cannot be defined within TokenData, cause struct containing mappings cannot be constructed.
    mapping(uint256 => mapping(address => uint256)) private _approvedValues;

    TokenData[] private _allTokens;

    //key: id
    mapping(uint256 => uint256) private _allTokensIndex;

    mapping(address => AddressData) private _addressData;

    // solhint-disable-next-line
    function __ERC3525_init(string memory name_, string memory symbol_, uint8 decimals_) internal onlyInitializing {
        __ERC3525_init_unchained(name_, symbol_, decimals_);
    }

    // solhint-disable-next-line
    function __ERC3525_init_unchained(string memory name_, string memory symbol_, uint8 decimals_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC3525).interfaceId ||
            interfaceId == type(IERC3525Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals the token uses for value.
     */
    function valueDecimals() external view virtual override returns (uint8) {
        return _decimals;
    }

    function balanceOf(uint256 tokenId_) public view virtual override returns (uint256) {
        require(_exists(tokenId_), "ERC3525: balance query for nonexistent token");
        return _allTokens[_allTokensIndex[tokenId_]].balance;
    }

    // ERC721 Compatible
    function ownerOf(uint256 tokenId_) public view virtual override returns (address owner_) {
        require(_exists(tokenId_), "ERC3525: owner query for nonexistent token");
        owner_ = _allTokens[_allTokensIndex[tokenId_]].owner;
        require(owner_ != address(0), "ERC3525: owner query for nonexistent token");
    }

    function slotOf(uint256 tokenId_) public view virtual override returns (uint256) {
        require(_exists(tokenId_), "ERC3525: slot query for nonexistent token");
        return _allTokens[_allTokensIndex[tokenId_]].slot;
    }

    function contractURI() external view virtual override returns (string memory) {
        return 
            string(
                abi.encodePacked(
                    // solhint-disable-next-line
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            // solhint-disable-next-line
                            '{"name":"', 
                            _name,
                            // solhint-disable-next-line
                            '","symbol":"', 
                            _symbol, 
                            // solhint-disable-next-line
                            '","description":"',
                            _contractDescription(),
                            // solhint-disable-next-line
                            '","valueDecimals":"', 
                            uint256(_decimals).toString(),
                            // solhint-disable-next-line
                            '"}'
                        )
                    )
                )
            );
    }

    function slotURI(uint256 slot_) external view virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    // solhint-disable-next-line
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            // solhint-disable-next-line
                            '{"name":"', 
                            _slotName(slot_),
                            // solhint-disable-next-line
                            '","description":"',
                            _slotDescription(slot_),
                            // solhint-disable-next-line
                            '","image":"',
                            _slotImage(slot_),
                            // solhint-disable-next-line
                            '","properties":',
                            _slotProperties(slot_),
                            // solhint-disable-next-line
                            '}'
                        )
                    )
                )
            );
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId_) external view virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            // solhint-disable-next-line
                            '{"name":"',
                            _tokenName(tokenId_),
                            // solhint-disable-next-line
                            '","description":"',
                            _tokenDescription(tokenId_),
                            // solhint-disable-next-line
                            '","image":"',
                            _tokenImage(tokenId_),
                            // solhint-disable-next-line
                            '","balance":"',
                            _allTokens[_allTokensIndex[tokenId_]].balance.toString(),
                            // solhint-disable-next-line
                            '","slot":"',
                            slotOf(tokenId_).toString(),
                            // solhint-disable-next-line
                            '","properties":',
                            _tokenProperties(tokenId_),
                            "}"
                        )
                    )
                )
            );
    }

    function approve(uint256 tokenId_, address to_, uint256 value_) external payable virtual override {
        address owner = ERC3525Upgradeable.ownerOf(tokenId_);
        require(to_ != owner, "ERC3525: approval to current owner");

        require(
            _msgSender() == owner || ERC3525Upgradeable.isApprovedForAll(owner, _msgSender()),
            "ERC3525: approve caller is not owner nor approved for all"
        );

        _approveValue(tokenId_, to_, value_);
    }

    function allowance(uint256 tokenId_, address operator_) public view virtual override returns (uint256) {
        return _approvedValues[tokenId_][operator_];
    }

    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) external payable virtual override returns (uint256) {
        _spendAllowance(_msgSender(), fromTokenId_, value_);

        uint256 newTokenId = _createTokenId();
        _mint(to_, newTokenId, ERC3525Upgradeable.slotOf(fromTokenId_));
        _transfer(fromTokenId_, newTokenId, value_);

        return newTokenId;
    }

    function safeTransferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_,
        bytes calldata data_
    ) external payable virtual override returns (uint256) {
        _spendAllowance(_msgSender(), fromTokenId_, value_);

        uint256 newTokenId = _createTokenId();
        _mint(to_, newTokenId, ERC3525Upgradeable.slotOf(fromTokenId_));
        _safeTransfer(fromTokenId_, newTokenId, value_, data_);

        return newTokenId;
    }

    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) external payable virtual override {
        _spendAllowance(_msgSender(), fromTokenId_, value_);

        _transfer(fromTokenId_, toTokenId_, value_);
    }

    function safeTransferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_,
        bytes calldata data_
    ) external payable virtual override {
        _spendAllowance(_msgSender(), fromTokenId_, value_);
        
        _safeTransfer(fromTokenId_, toTokenId_, value_, data_);
    }

    function balanceOf(address owner_) public view virtual override returns (uint256 balance) {
        require(owner_ != address(0), "ERC3525: balance query for the zero address");
        return _addressData[owner_].ownedTokens.length;
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) external virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: transfer caller is not owner nor approved");

        _transfer(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: transfer caller is not owner nor approved");
        _safeTransfer(from_, to_, tokenId_, data_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) external virtual override {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    function approve(address to_, uint256 tokenId_) external virtual override {
        address owner = ERC3525Upgradeable.ownerOf(tokenId_);
        require(to_ != owner, "ERC3525: approval to current owner");

        require(
            _msgSender() == owner || ERC3525Upgradeable.isApprovedForAll(owner, _msgSender()),
            "ERC3525: approve caller is not owner nor approved for all"
        );

        _approve(to_, tokenId_);
    }

    function getApproved(uint256 tokenId_) public view virtual override returns (address) {
        require(_exists(tokenId_), "ERC3525: approved query for nonexistent token");

        return _allTokens[_allTokensIndex[tokenId_]].approved;
    }

    function setApprovalForAll(address operator_, bool approved_) external virtual override {
        _setApprovalForAll(_msgSender(), operator_, approved_);
    }

    function isApprovedForAll(address owner_, address operator_) public view virtual override returns (bool) {
        return _addressData[owner_].approvals[operator_];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index_) external view virtual override returns (uint256) {
        require(index_ < ERC3525Upgradeable.totalSupply(), "ERC3525: global index out of bounds");
        return _allTokens[index_].id;
    }

    function tokenOfOwnerByIndex(address owner_, uint256 index_) external view virtual override returns (uint256) {
        require(index_ < ERC3525Upgradeable.balanceOf(owner_), "ERC3525: owner index out of bounds");
        return _addressData[owner_].ownedTokens[index_];
    }

    function _setApprovalForAll(
        address owner_,
        address operator_,
        bool approved_
    ) internal virtual {
        require(owner_ != operator_, "ERC3525: approve to caller");

        _addressData[owner_].approvals[operator_] = approved_;

        emit ApprovalForAll(owner_, operator_, approved_);
    }

    function _isApprovedOrOwner(address operator_, uint256 tokenId_) internal view virtual returns (bool) {
        require(_exists(tokenId_), "ERC3525: operator query for nonexistent token");
        address owner = ERC3525Upgradeable.ownerOf(tokenId_);
        return (
            operator_ == owner ||
            ERC3525Upgradeable.isApprovedForAll(owner, operator_) ||
            getApproved(tokenId_) == operator_
        );
    }

    function _spendAllowance(address operator_, uint256 tokenId_, uint256 value_) internal virtual {
        uint256 currentAllowance = ERC3525Upgradeable.allowance(tokenId_, operator_);
        if (!_isApprovedOrOwner(operator_, tokenId_) && currentAllowance != type(uint256).max) {
            require(currentAllowance >= value_, "ERC3525: insufficient allowance");
            _approveValue(tokenId_, operator_, currentAllowance - value_);
        }
    }

    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return _allTokens.length != 0 && _allTokens[_allTokensIndex[tokenId_]].id == tokenId_;
    }

    function _mintValue(address to_, uint256 tokenId_, uint256 slot_, uint256 value_) internal virtual {
        require(to_ != address(0), "ERC3525: mint to the zero address");
        require(tokenId_ != 0, "ERC3525: cannot mint zero tokenId");
        require(!_exists(tokenId_), "ERC3525: token already minted");

        _beforeValueTransfer(address(0), to_, 0, tokenId_, slot_, value_);

        _mint(to_, tokenId_, slot_);
        _allTokens[_allTokensIndex[tokenId_]].balance = value_;

        emit TransferValue(0, tokenId_, value_);

        _beforeValueTransfer(address(0), to_, 0, tokenId_, slot_, value_);
    }

    function _mint(address to_, uint256 tokenId_, uint256 slot_) private {
        TokenData memory tokenData = TokenData({
            id: tokenId_,
            slot: slot_,
            balance: 0,
            owner: to_,
            approved: address(0),
            valueApprovals: new address[](0)
        });

        _addTokenToAllTokensEnumeration(tokenData);
        _addTokenToOwnerEnumeration(to_, tokenId_);

        emit Transfer(address(0), to_, tokenId_);
        emit SlotChanged(tokenId_, 0, slot_);
    }

    function _burn(uint256 tokenId_) internal virtual {
        require(_exists(tokenId_), "ERC3525: token does not exist");

        TokenData storage tokenData = _allTokens[_allTokensIndex[tokenId_]];
        address owner = tokenData.owner;
        uint256 slot = tokenData.slot;
        uint256 value = tokenData.balance;

        _beforeValueTransfer(owner, address(0), tokenId_, 0, slot, value);

        _clearApprovedValues(tokenId_);
        _removeTokenFromAllTokensEnumeration(tokenId_);
        _removeTokenFromOwnerEnumeration(owner, tokenId_);

        emit TransferValue(tokenId_, 0, value);
        emit Transfer(owner, address(0), tokenId_);
        emit SlotChanged(tokenId_, slot, 0);

        _afterValueTransfer(owner, address(0), tokenId_, 0, slot, value);
    }

    function _addTokenToOwnerEnumeration(address to_, uint256 tokenId_) private {
        _allTokens[_allTokensIndex[tokenId_]].owner = to_;

        _addressData[to_].ownedTokensIndex[tokenId_] = _addressData[to_].ownedTokens.length;
        _addressData[to_].ownedTokens.push(tokenId_);
    }

    function _removeTokenFromOwnerEnumeration(address from_, uint256 tokenId_) private {
        _allTokens[_allTokensIndex[tokenId_]].owner = address(0);

        AddressData storage ownerData = _addressData[from_];
        uint256 lastTokenIndex = ownerData.ownedTokens.length - 1;
        uint256 lastTokenId = ownerData.ownedTokens[lastTokenIndex];
        uint256 tokenIndex = ownerData.ownedTokensIndex[tokenId_];

        ownerData.ownedTokens[tokenIndex] = lastTokenId;
        ownerData.ownedTokensIndex[lastTokenId] = tokenIndex;

        delete ownerData.ownedTokensIndex[tokenId_];
        ownerData.ownedTokens.pop();
    }

    function _addTokenToAllTokensEnumeration(TokenData memory tokenData_) private {
        _allTokensIndex[tokenData_.id] = _allTokens.length;
        _allTokens.push(tokenData_);
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId_) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId_];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        TokenData memory lastTokenData = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenData; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenData.id] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId_];
        _allTokens.pop();
    }

    function _approve(address to_, uint256 tokenId_) internal virtual {
        _allTokens[_allTokensIndex[tokenId_]].approved = to_;
        emit Approval(ERC3525Upgradeable.ownerOf(tokenId_), to_, tokenId_);
    }

    function _approveValue(
        uint256 tokenId_,
        address to_,
        uint256 value_
    ) internal virtual {
        if (!_existApproveValue(to_, tokenId_)) {
            _allTokens[_allTokensIndex[tokenId_]].valueApprovals.push(to_);
        }
        _approvedValues[tokenId_][to_] = value_;

        emit ApprovalValue(tokenId_, to_, value_);
    }

    function _clearApprovedValues(uint256 tokenId_) internal virtual {
        TokenData storage tokenData = _allTokens[_allTokensIndex[tokenId_]];
        uint256 length = tokenData.valueApprovals.length;
        for (uint256 i = 0; i < length; i++) {
            address approval = tokenData.valueApprovals[i];
            delete _approvedValues[tokenId_][approval];
        }
    }

    function _existApproveValue(address to_, uint256 tokenId_) internal view virtual returns (bool) {
        uint256 length = _allTokens[_allTokensIndex[tokenId_]].valueApprovals.length;
        for (uint256 i = 0; i < length; i++) {
            if (_allTokens[_allTokensIndex[tokenId_]].valueApprovals[i] == to_) {
                return true;
            }
        }
        return false;
    }

    function _transfer(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) internal virtual {
        require(_exists(fromTokenId_), "ERC35255: transfer from nonexistent token");
        require(_exists(toTokenId_), "ERC35255: transfer to nonexistent token");

        TokenData storage fromTokenData = _allTokens[_allTokensIndex[fromTokenId_]];
        TokenData storage toTokenData = _allTokens[_allTokensIndex[toTokenId_]];

        require(fromTokenData.balance >= value_, "ERC3525: transfer amount exceeds balance");
        require(fromTokenData.slot == toTokenData.slot, "ERC3535: transfer to token with different slot");

        _beforeValueTransfer(
            fromTokenData.owner,
            toTokenData.owner,
            fromTokenId_,
            toTokenId_,
            fromTokenData.slot,
            value_
        );

        fromTokenData.balance -= value_;
        toTokenData.balance += value_;

        emit TransferValue(fromTokenId_, toTokenId_, value_);

        _afterValueTransfer(
            fromTokenData.owner,
            toTokenData.owner,
            fromTokenId_,
            toTokenId_,
            fromTokenData.slot,
            value_
        );
    }

    function _safeTransfer(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_,
        bytes memory data_
    ) internal virtual {
        _transfer(fromTokenId_, toTokenId_, value_);
        require(
            _checkOnERC3525Received(fromTokenId_, toTokenId_, value_, data_),
            "ERC3525: transfer to non ERC3525Receiver implementer"
        );
    }

    function _transfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual {
        require(ERC3525Upgradeable.ownerOf(tokenId_) == from_, "ERC3525: transfer from incorrect owner");
        require(to_ != address(0), "ERC3525: transfer to the zero address");

        _approve(address(0), tokenId_);
        _clearApprovedValues(tokenId_);

        _removeTokenFromOwnerEnumeration(from_, tokenId_);
        _addTokenToOwnerEnumeration(to_, tokenId_);

        emit Transfer(from_, to_, tokenId_);
    }

    function _safeTransfer(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) internal virtual {
        _transfer(from_, to_, tokenId_);
        require(
            _checkOnERC721Received(from_, to_, tokenId_, data_),
            "ERC3525: transfer to non ERC721Receiver implementer"
        );
    }

    function _checkOnERC3525Received(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_,
        bytes memory data_
    ) private returns (bool) {
        address to = ERC3525Upgradeable.ownerOf((toTokenId_));
        if (to.isContract()) {
            try IERC3525Receiver(to).onERC3525Received(_msgSender(), fromTokenId_, toTokenId_, value_, data_) returns (
                bytes4 retval
            ) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC3525: transfer to non ERC3525Receiver implementer");
                } else {
                    // solhint-disable-next-line
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from_ address representing the previous owner of the given token ID
     * @param to_ target address that will receive the tokens
     * @param tokenId_ uint256 ID of the token to be transferred
     * @param data_ bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) private returns (bool) {
        if (to_.isContract()) {
            try IERC721Receiver(to_).onERC721Received(_msgSender(), from_, tokenId_, data_) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual {}

    function _afterValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual {}

    function _createTokenId() internal virtual returns (uint256);

    function _contractDescription() internal view virtual returns (string memory) {
        return "";
    }

    function _slotName(uint256 slot_) internal view virtual returns (string memory) {
        slot_;
        return "";
    }

    function _slotDescription(uint256 slot_) internal view virtual returns (string memory) {
        slot_;
        return "";
    }

    function _slotImage(uint256 slot_) internal view virtual returns (bytes memory) {
        slot_;
        return "";
    }

    function _slotProperties(uint256 slot_) internal view virtual returns (string memory) {
        slot_;
        return "[]";
    }

    function _tokenName(uint256 tokenId_) internal view virtual returns (string memory) {
        // solhint-disable-next-line
        return string(abi.encodePacked('"', _name, " #", tokenId_.toString(), '"'));
    }

    function _tokenDescription(uint256 tokenId_) internal view virtual returns (string memory) {
        // solhint-disable-next-line
        return string(abi.encodePacked('" #', tokenId_.toString(), " of ", _name, '"'));
    }

    function _tokenImage(uint256 tokenId_) internal view virtual returns (bytes memory) {
        tokenId_;
        return "";
    }

    function _tokenProperties(uint256 tokenId_) internal view virtual returns (string memory) {
        tokenId_;
        return "[]";
    }
}
