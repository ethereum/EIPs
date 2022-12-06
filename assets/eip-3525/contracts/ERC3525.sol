//SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "./interface/IERC3525.sol";
import "./interface/IERC3525Metadata.sol";
import "./interface/IERC3525Receiver.sol";

contract ERC3525 is IERC3525, IERC3525Metadata, ERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    struct ApproveData {
        address[] approvals;
        mapping(address => uint256) allowances;
    }

    /// @dev tokenId => values
    mapping(uint256 => uint256) internal _values;

    /// @dev tokenId => operator => units
    mapping(uint256 => ApproveData) private _approvedValues;

    /// @dev tokenId => slot
    mapping(uint256 => uint256) internal _slots;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor( string memory name_, string memory symbol_, uint8 decimals_) ERC721(name_, symbol_) {
        _decimals = decimals_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Enumerable) returns (bool)
    {
        return
            interfaceId == type(IERC3525).interfaceId ||
            interfaceId == type(IERC3525Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function valueDecimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function balanceOf(uint256 tokenId_) public view virtual override returns (uint256)
    {
        require( _exists(tokenId_), "ERC3525: balance query for nonexistent token");
        return _values[tokenId_];
    }

    function slotOf(uint256 tokenId_) public view virtual override returns (uint256)
    {
        require(_exists(tokenId_), "ERC3525: slot query for nonexistent token");
        return _slots[tokenId_];
    }

    function contractURI() public view virtual override returns (string memory)
    {
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string( abi.encodePacked( baseURI, "contract/", Strings.toHexString(uint256(uint160(address(this)))))) : "";
    }

    function slotURI(uint256 slot_) public view virtual override returns (string memory)
    {
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "slot/", slot_.toString())) : "";
    }

    function approve( uint256 tokenId_, address to_, uint256 value_) external payable virtual override {
        address owner = ERC721.ownerOf(tokenId_);
        require(to_ != owner, "ERC3525: approval to current owner");

        require(
            ERC721._isApprovedOrOwner(_msgSender(), tokenId_),
            "ERC3525: approve caller is not owner nor approved for all"
        );

        _approveValue(tokenId_, to_, value_);
    }

    function allowance(uint256 tokenId_, address operator_) public view virtual override returns (uint256)
    {
        return _approvedValues[tokenId_].allowances[operator_];
    }

    function transferFrom( uint256 fromTokenId_, address to_, uint256 value_) public payable virtual override returns (uint256) {
        _spendAllowance(_msgSender(), fromTokenId_, value_);

        uint256 newTokenId = _getNewTokenId(fromTokenId_);
        _mint(to_, newTokenId, _slots[fromTokenId_]);
        _transfer(fromTokenId_, newTokenId, value_);

        return newTokenId;
    }

    function transferFrom( uint256 fromTokenId_, uint256 toTokenId_, uint256 value_) public payable virtual override {
        _spendAllowance(_msgSender(), fromTokenId_, value_);

        _transfer(fromTokenId_, toTokenId_, value_);
    }

    function _mint( address to_, uint256 tokenId_, uint256 slot_) private {
        ERC721._mint(to_, tokenId_);
        _slots[tokenId_] = slot_;
        emit SlotChanged(tokenId_, 0, slot_);
    }

    function _mintValue( address to_, uint256 tokenId_, uint256 slot_, uint256 value_) internal virtual {
        require(to_ != address(0), "ERC3525: mint to the zero address");
        require(tokenId_ != 0, "ERC3525: cannot mint zero tokenId");
        require(!_exists(tokenId_), "ERC3525: token already minted");

        _mint(to_, tokenId_, slot_);

        _beforeValueTransfer(address(0), to_, 0, tokenId_, slot_, value_);
        _values[tokenId_] = value_;
        _afterValueTransfer(address(0), to_, 0, tokenId_, slot_, value_);

        emit TransferValue(0, tokenId_, value_);
    }

    function _burn(uint256 tokenId_) internal virtual override {
        address owner = ERC721.ownerOf(tokenId_);
        ERC721._burn(tokenId_);

        uint256 slot = _slots[tokenId_];
        uint256 value = _values[tokenId_];

        _beforeValueTransfer(owner, address(0), tokenId_, 0, slot, value);
        delete _slots[tokenId_];
        delete _values[tokenId_];
        _afterValueTransfer(owner, address(0), tokenId_, 0, slot, value);
        
        emit TransferValue(tokenId_, 0, value);
        emit SlotChanged(tokenId_, slot, 0);
    }

    function _transfer( uint256 fromTokenId_, uint256 toTokenId_, uint256 value_) internal virtual {
        require( _exists(fromTokenId_),
            "ERC35255: transfer from nonexistent token");
        require(_exists(toTokenId_), "ERC35255: transfer to nonexistent token");

        require( _values[fromTokenId_] >= value_,
            "ERC3525: transfer amount exceeds balance");
        require( _slots[fromTokenId_] == _slots[toTokenId_],
            "ERC3535: transfer to token with different slot");

        address from = ERC721.ownerOf(fromTokenId_);
        address to = ERC721.ownerOf(toTokenId_);
        _beforeValueTransfer(from, to, fromTokenId_, toTokenId_, _slots[fromTokenId_], value_);

        _values[fromTokenId_] -= value_;
        _values[toTokenId_] += value_;

        _afterValueTransfer(from, to, fromTokenId_, toTokenId_, _slots[fromTokenId_], value_);

        emit TransferValue(fromTokenId_, toTokenId_, value_);
    }

    function _spendAllowance( address operator_, uint256 tokenId_, uint256 value_) internal virtual {
        uint256 currentAllowance = ERC3525.allowance(tokenId_, operator_);
        if ( !_isApprovedOrOwner(operator_, tokenId_) && currentAllowance != type(uint256).max) {
            require( currentAllowance >= value_, "ERC3525: insufficient allowance");
            _approveValue(tokenId_, operator_, currentAllowance - value_);
        }
    }

    function _approveValue( uint256 tokenId_, address to_, uint256 value_) internal virtual {
        ApproveData storage approveData = _approvedValues[tokenId_];
        approveData.approvals.push(to_);
        approveData.allowances[to_] = value_;

        emit ApprovalValue(tokenId_, to_, value_);
    }

    function _getNewTokenId(uint256 fromTokenId_) internal virtual returns (uint256)
    {
        return ERC721Enumerable.totalSupply() + 1;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        //clear approve data
        uint256 length = _approvedValues[tokenId].approvals.length;
        for (uint256 i = 0; i < length; i++) {
            address approval = _approvedValues[tokenId].approvals[i];
            delete _approvedValues[tokenId].allowances[approval];
        }
        delete _approvedValues[tokenId].approvals;
    }
        
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {}

    function _checkOnERC3525Received( uint256 fromTokenId_, uint256 toTokenId_, uint256 value_, bytes memory data_) private returns (bool) {
        address to = ERC721.ownerOf((toTokenId_));
        if (to.isContract() && IERC165(to).supportsInterface(type(IERC3525Receiver).interfaceId)) {
            try
                IERC3525Receiver(to).onERC3525Received( _msgSender(), fromTokenId_, toTokenId_, value_, data_)
            returns (bytes4 retval) {
                return retval == IERC3525Receiver.onERC3525Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert( "ERC3525: transfer to non ERC3525Receiver implementer");
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

    function _beforeValueTransfer( address from_, address to_, uint256 fromTokenId_, uint256 toTokenId_, uint256 slot_, uint256 value_) internal virtual {}

    function _afterValueTransfer( address from_, address to_, uint256 fromTokenId_, uint256 toTokenId_, uint256 slot_, uint256 value_) internal virtual {}
}
