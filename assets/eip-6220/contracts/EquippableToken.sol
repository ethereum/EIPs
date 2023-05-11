// SPDX-License-Identifier: CC0-1.0

//Generally all interactions should propagate downstream

pragma solidity ^0.8.16;

import "./ICatalog.sol";
import "./IERC6220.sol";
import "./IERC6059.sol";
import "./library/EquippableLib.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

error ApprovalForAssetsToCurrentOwner();
error ApproveForAssetsCallerIsNotOwnerNorApprovedForAll();
error AssetAlreadyExists();
error BadPriorityListLength();
error CatalogRequiredForParts();
error ChildAlreadyExists();
error ChildIndexOutOfRange();
error EquippableEquipNotAllowedByCatalog();
error ERC721AddressZeroIsNotaValidOwner();
error ERC721ApprovalToCurrentOwner();
error ERC721ApproveCallerIsNotOwnerNorApprovedForAll();
error ERC721ApproveToCaller();
error ERC721InvalidTokenId();
error ERC721MintToTheZeroAddress();
error ERC721NotApprovedOrOwner();
error ERC721TokenAlreadyMinted();
error ERC721TransferFromIncorrectOwner();
error ERC721TransferToNonReceiverImplementer();
error ERC721TransferToTheZeroAddress();
error IdZeroForbidden();
error IndexOutOfRange();
error IsNotContract();
error MaxPendingAssetsReached();
error MaxPendingChildrenReached();
error MaxRecursiveBurnsReached(address childContract, uint256 childId);
error MintToNonNestableImplementer();
error MustUnequipFirst();
error NestableTooDeep();
error NestableTransferToDescendant();
error NestableTransferToNonNestableImplementer();
error NestableTransferToSelf();
error NoAssetMatchingId();
error NotApprovedForAssetsOrOwner();
error NotApprovedOrDirectOwner();
error NotEquipped();
error PendingChildIndexOutOfRange();
error SlotAlreadyUsed();
error TargetAssetCannotReceiveSlot();
error TokenCannotBeEquippedWithAssetIntoSlot();
error TokenDoesNotHaveAsset();
error UnexpectedAssetId();
error UnexpectedChildId();
error UnexpectedNumberOfAssets();
error UnexpectedNumberOfChildren();

/**
 * @title EquippableToken
 * @author RMRK team
 * @notice Smart contract of the Equippable module.
 */
contract EquippableToken is
    Context,
    IERC165,
    IERC721,
    IERC6059,
    IERC6220
{
    using Address for address;
    using EquippableLib for uint64[];

    // ----------------- ERC721 -------------

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approver address to approved address
    // The approver is necessary so approvals are invalidated for nested children on transfer
    // WARNING: If a child NFT returns to a previous root owner, old permissions would be active again
    mapping(uint256 => mapping(address => address)) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // ----------------- MULTIASSETS -------------

    /// Mapping of uint64 Ids to asset metadata
    mapping(uint64 => string) private _assets;

    /// Mapping of tokenId to new asset, to asset to be replaced
    mapping(uint256 => mapping(uint64 => uint64)) private _assetReplacements;

    /// Mapping of tokenId to an array of active assets
    /// @dev Active recurses is unbounded, getting all would reach gas limit at around 30k items
    /// so we leave this as internal in case a custom implementation needs to implement pagination
    mapping(uint256 => uint64[]) internal _activeAssets;

    /// Mapping of tokenId to an array of pending assets
    mapping(uint256 => uint64[]) internal _pendingAssets;

    /// Mapping of tokenId to an array of priorities for active assets
    mapping(uint256 => uint16[]) internal _activeAssetPriorities;

    /// Mapping of tokenId to assetId to whether the token has this asset assigned
    mapping(uint256 => mapping(uint64 => bool)) private _tokenAssets;

    /// Mapping from owner to operator approvals for assets
    mapping(address => mapping(address => bool))
        private _operatorApprovalsForAssets;

    /**
     * @notice Mapping from token ID to approver address to approved address for assets.
     * @dev The approver is necessary so approvals are invalidated for nested children on transfer.
     * @dev WARNING: If a child NFT returns the original root owner, old permissions would be active again.
     */
    mapping(uint256 => mapping(address => address))
        private _tokenApprovalsForAssets;

    // ------------------- NESTABLE --------------

    uint256 private constant _MAX_LEVELS_TO_CHECK_FOR_INHERITANCE_LOOP = 100;

    // Mapping from token ID to DirectOwner struct
    mapping(uint256 => DirectOwner) private _directOwners;

    // Mapping of tokenId to array of active children structs
    mapping(uint256 => Child[]) private _activeChildren;

    // Mapping of tokenId to array of pending children structs
    mapping(uint256 => Child[]) private _pendingChildren;

    // Mapping of child token address to child token ID to whether they are pending or active on any token
    // We might have a first extra mapping from token ID, but since the same child cannot be nested into multiple tokens
    //  we can strip it for size/gas savings.
    mapping(address => mapping(uint256 => uint256)) private _childIsInActive;

    // ------------------- EQUIPPABLE --------------

    /// Mapping of uint64 asset ID to corresponding catalog address.
    mapping(uint64 => address) private _catalogAddresses;
    /// Mapping of uint64 ID to asset object.
    mapping(uint64 => uint64) private _equippableGroupIds;
    /// Mapping of assetId to catalog parts applicable to this asset, both fixed and slot
    mapping(uint64 => uint64[]) private _partIds;

    /// Mapping of token ID to catalog address to slot part ID to equipment information. Used to compose an NFT.
    mapping(uint256 => mapping(address => mapping(uint64 => Equipment)))
        private _equipments;

    /// Mapping of token ID to child (nestable) address to child ID to count of equipped items. Used to check if equipped.
    mapping(uint256 => mapping(address => mapping(uint256 => uint8)))
        private _equipCountPerChild;

    /// Mapping of `equippableGroupId` to parent contract address and valid `slotId`.
    mapping(uint64 => mapping(address => uint64)) private _validParentSlots;

    // -------------------------- MODIFIERS ----------------------------

    /**
     * @notice Used to verify that the caller is either the owner of the token or approved to manage it by its owner.
     * @param tokenId ID of the token to check
     */
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        _onlyApprovedOrOwner(tokenId);
        _;
    }

    /**
     * @notice Used to verify that the caller is approved to manage the given token or is its direct owner.
     * @param tokenId ID of the token to check
     */
    modifier onlyApprovedOrDirectOwner(uint256 tokenId) {
        _onlyApprovedOrDirectOwner(tokenId);
        _;
    }

    /**
     * @notice Used to ensure that the caller is either the owner of the given token or approved to manage the token's assets
     *  of the owner.
     * @dev If that is not the case, the execution of the function will be reverted.
     * @param tokenId ID of the token that we are checking
     */
    modifier onlyApprovedForAssetsOrOwner(uint256 tokenId) {
        _onlyApprovedForAssetsOrOwner(tokenId);
        _;
    }

    // --------------------- ERC721 GETTERS ---------------------

    /**
     * @notice Used to retrieve the root owner of the given token.
     * @dev Root owner is always the externally owned account.
     * @dev If the given token is owned by another token, it will recursively query the parent tokens until reaching the
     *  root owner.
     * @param tokenId ID of the token for which the root owner is being retrieved
     * @return address Address of the root owner of the given token
     */
    function ownerOf(
        uint256 tokenId
    ) public view virtual override(IERC6059, IERC721) returns (address) {
        (address owner, uint256 ownerTokenId, bool isNft) = directOwnerOf(
            tokenId
        );
        if (isNft) {
            owner = IERC6059(owner).ownerOf(ownerTokenId);
        }
        return owner;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC5773).interfaceId ||
            interfaceId == type(IERC6059).interfaceId ||
            interfaceId == type(IERC6220).interfaceId;
    }

    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert ERC721AddressZeroIsNotaValidOwner();
        return _balances[owner];
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(
        uint256 tokenId
    ) public view virtual returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId][ownerOf(tokenId)];
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // --------------------- ERC721 SETTERS ---------------------

    /**
     * @inheritdoc IERC721
     */
    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ERC721ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()))
            revert ERC721ApproveCallerIsNotOwnerNorApprovedForAll();

        _approve(to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        if (_msgSender() == operator) revert ERC721ApproveToCaller();
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @notice Used to burn a given token.
     * @param tokenId ID of the token to burn
     */
    function burn(uint256 tokenId) public virtual {
        burn(tokenId, 0);
    }

    /**
     * @notice Used to burn a token.
     * @dev When a token is burned, its children are recursively burned as well.
     * @dev The approvals are cleared when the token is burned.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @dev Emits a {Transfer} event.
     * @param tokenId ID of the token to burn
     * @param maxChildrenBurns Maximum children to recursively burn
     * @return uint256 The number of recursive burns it took to burn all of the children
     */
    function burn(
        uint256 tokenId,
        uint256 maxChildrenBurns
    ) public virtual onlyApprovedOrDirectOwner(tokenId) returns (uint256) {
        return _burn(tokenId, maxChildrenBurns);
    }

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _transfer(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _safeTransfer(from, to, tokenId, data);
    }

    // --------------------- ERC721 INTERNAL ---------------------

    /**
     * @notice Used to grant an approval to manage a given token.
     * @dev Emits an {Approval} event.
     * @param to Address to which the approval is being granted
     * @param tokenId ID of the token for which the approval is being granted
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        _tokenApprovals[tokenId][owner] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @notice Used to update the owner of the token and clear the approvals associated with the previous owner.
     * @dev The `destinationId` should equal `0` if the new owner is an externally owned account.
     * @param tokenId ID of the token being updated
     * @param destinationId ID of the token to receive the given token
     * @param to Address of account to receive the token
     * @param isNft A boolean value signifying whether the new owner is a token (`true`) or externally owned account
     *  (`false`)
     */
    function _updateOwnerAndClearApprovals(
        uint256 tokenId,
        uint256 destinationId,
        address to,
        bool isNft
    ) internal {
        _directOwners[tokenId] = DirectOwner({
            ownerAddress: to,
            tokenId: destinationId,
            isNft: isNft
        });

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _approveForAssets(address(0), tokenId);
    }

    /**
     * @notice Used to enforce that the given token has been minted.
     * @dev Reverts if the `tokenId` has not been minted yet.
     * @dev The validation checks whether the owner of a given token is a `0x0` address and considers it not minted if
     *  it is. This means that both tokens that haven't been minted yet as well as the ones that have already been
     *  burned will cause the transaction to be reverted.
     * @param tokenId ID of the token to check
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        if (!_exists(tokenId)) revert ERC721InvalidTokenId();
    }

    /**
     * @notice Used to check whether the given token exists.
     * @dev Tokens start existing when they are minted (`_mint`) and stop existing when they are burned (`_burn`).
     * @param tokenId ID of the token being checked
     * @return bool The boolean value signifying whether the token exists
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _directOwners[tokenId].ownerAddress != address(0);
    }

    /**
     * @notice Used to invoke {IERC721Receiver-onERC721Received} on a target address.
     * @dev The call is not executed if the target address is not a contract.
     * @param from Address representing the previous owner of the given token
     * @param to Yarget address that will receive the tokens
     * @param tokenId ID of the token to be transferred
     * @param data Optional data to send along with the call
     * @return bool Boolean value signifying whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721TransferToNonReceiverImplementer();
                } else {
                    /// @solidity memory-safe-assembly
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
     * @notice Used to safely mint a token to a specified address.
     * @dev Requirements:
     *
     *  - `tokenId` must not exist.
     *  - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * @dev Emits a {Transfer} event.
     * @param to Address to which to safely mint the gven token
     * @param tokenId ID of the token to mint to the specified address
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @notice Used to safely mint the token to the specified address while passing the additional data to contract
     *  recipients.
     * @param to Address to which to mint the token
     * @param tokenId ID of the token to mint
     * @param data Additional data to send with the tokens
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, data))
            revert ERC721TransferToNonReceiverImplementer();
    }

    /**
     * @notice Used to mint a specified token to a given address.
     * @dev WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible.
     * @dev Requirements:
     *
     *  - `tokenId` must not exist.
     *  - `to` cannot be the zero address.
     * @dev Emits a {Transfer} event.
     * @param to Address to mint the token to
     * @param tokenId ID of the token to mint
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        _innerMint(to, tokenId, 0);

        emit Transfer(address(0), to, tokenId);
        emit NestTransfer(address(0), to, 0, 0, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
        _afterNestedTokenTransfer(address(0), to, 0, 0, tokenId);
    }

    /**
     * @notice Used to mint a child token to a given parent token.
     * @param to Address of the collection smart contract of the token into which to mint the child token
     * @param tokenId ID of the token to mint
     * @param destinationId ID of the token into which to mint the new child token
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _nestMint(
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) internal virtual {
        // It seems redundant, but otherwise it would revert with no error
        if (!to.isContract()) revert IsNotContract();
        if (!IERC165(to).supportsInterface(type(IERC6059).interfaceId))
            revert MintToNonNestableImplementer();

        _innerMint(to, tokenId, destinationId);
        _sendToNFT(address(0), to, 0, destinationId, tokenId, data);
    }

    /**
     * @notice Used to mint a child token into a given parent token.
     * @dev Requirements:
     *
     *  - `to` cannot be the zero address.
     *  - `tokenId` must not exist.
     *  - `tokenId` must not be `0`.
     * @param to Address of the collection smart contract of the token into which to mint the child token
     * @param tokenId ID of the token to mint
     * @param destinationId ID of the token into which to mint the new token
     */
    function _innerMint(
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) private {
        if (to == address(0)) revert ERC721MintToTheZeroAddress();
        if (_exists(tokenId)) revert ERC721TokenAlreadyMinted();
        if (tokenId == 0) revert IdZeroForbidden();

        _beforeTokenTransfer(address(0), to, tokenId);
        _beforeNestedTokenTransfer(address(0), to, 0, destinationId, tokenId);

        _balances[to] += 1;
        _directOwners[tokenId] = DirectOwner({
            ownerAddress: to,
            tokenId: destinationId,
            isNft: destinationId != 0
        });
    }

    /**
     * @notice Used to burn a token.
     * @dev When a token is burned, its children are recursively burned as well.
     * @dev The approvals are cleared when the token is burned.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @dev Emits a {Transfer} event.
     * @dev Emits a {NestTransfer} event.
     * @param tokenId ID of the token to burn
     * @param maxChildrenBurns Maximum children to recursively burn
     * @return uint256 The number of recursive burns it took to burn all of the children
     */
    function _burn(
        uint256 tokenId,
        uint256 maxChildrenBurns
    ) internal virtual returns (uint256) {
        (address immediateOwner, uint256 parentId, ) = directOwnerOf(tokenId);
        address owner = ownerOf(tokenId);
        _balances[immediateOwner] -= 1;

        _beforeTokenTransfer(owner, address(0), tokenId);
        _beforeNestedTokenTransfer(
            immediateOwner,
            address(0),
            parentId,
            0,
            tokenId
        );

        _approve(address(0), tokenId);
        _approveForAssets(address(0), tokenId);

        Child[] memory children = childrenOf(tokenId);

        delete _activeChildren[tokenId];
        delete _pendingChildren[tokenId];
        delete _tokenApprovals[tokenId][owner];

        uint256 pendingRecursiveBurns;
        uint256 totalChildBurns;

        uint256 length = children.length; //gas savings
        for (uint256 i; i < length; ) {
            if (totalChildBurns >= maxChildrenBurns)
                revert MaxRecursiveBurnsReached(
                    children[i].contractAddress,
                    children[i].tokenId
                );
            delete _childIsInActive[children[i].contractAddress][
                children[i].tokenId
            ];
            unchecked {
                // At this point we know pendingRecursiveBurns must be at least 1
                pendingRecursiveBurns = maxChildrenBurns - totalChildBurns;
            }
            // We substract one to the next level to count for the token being burned, then add it again on returns
            // This is to allow the behavior of 0 recursive burns meaning only the current token is deleted.
            totalChildBurns +=
                IERC6059(children[i].contractAddress).burn(
                    children[i].tokenId,
                    pendingRecursiveBurns - 1
                ) +
                1;
            unchecked {
                ++i;
            }
        }
        // Can't remove before burning child since child will call back to get root owner
        delete _directOwners[tokenId];

        _afterTokenTransfer(owner, address(0), tokenId);
        _afterNestedTokenTransfer(
            immediateOwner,
            address(0),
            parentId,
            0,
            tokenId
        );
        emit Transfer(owner, address(0), tokenId);
        emit NestTransfer(immediateOwner, address(0), parentId, 0, tokenId);

        return totalChildBurns;
    }

    /**
     * @notice Used to safely transfer the token form `from` to `to`.
     * @dev The function checks that contract recipients are aware of the ERC721 protocol to prevent tokens from being
     *  forever locked.
     * @dev This internal function is equivalent to {safeTransferFrom}, and can be used to e.g. implement alternative
     *  mechanisms to perform token transfer, such as signature-based.
     * @dev Requirements:
     *
     *  - `from` cannot be the zero address.
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must exist and be owned by `from`.
     *  - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * @dev Emits a {Transfer} event.
     * @param from Address of the account currently owning the given token
     * @param to Address to transfer the token to
     * @param tokenId ID of the token to transfer
     * @param data Additional data with no specified format, sent in call to `to`
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data))
            revert ERC721TransferToNonReceiverImplementer();
    }

    /**
     * @notice Used to transfer the token from `from` to `to`.
     * @dev As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @dev Requirements:
     *
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must be owned by `from`.
     * @dev Emits a {Transfer} event.
     * @param from Address of the account currently owning the given token
     * @param to Address to transfer the token to
     * @param tokenId ID of the token to transfer
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        (address immediateOwner, uint256 parentId, ) = directOwnerOf(tokenId);
        if (immediateOwner != from) revert ERC721TransferFromIncorrectOwner();
        if (to == address(0)) revert ERC721TransferToTheZeroAddress();

        _beforeTokenTransfer(from, to, tokenId);
        _beforeNestedTokenTransfer(immediateOwner, to, parentId, 0, tokenId);

        _balances[from] -= 1;
        _updateOwnerAndClearApprovals(tokenId, 0, to, false);
        _balances[to] += 1;

        emit Transfer(from, to, tokenId);
        emit NestTransfer(immediateOwner, to, parentId, 0, tokenId);

        _afterTokenTransfer(from, to, tokenId);
        _afterNestedTokenTransfer(immediateOwner, to, parentId, 0, tokenId);
    }

    // --------------------- NESTABLE GETTERS ---------------------

    /**
     * @notice Used to retrieve the immediate owner of the given token.
     * @dev In the event the NFT is owned by an externally owned account, `tokenId` will be `0` and `isNft` will be
     *  `false`.
     * @param tokenId ID of the token for which the immediate owner is being retrieved
     * @return address Address of the immediate owner. If the token is owned by an externally owned account, its address
     *  will be returned. If the token is owned by another token, the parent token's collection smart contract address
     *  is returned
     * @return uint256 Token ID of the immediate owner. If the immediate owner is an externally owned account, the value
     *  should be `0`
     * @return bool A boolean value signifying whether the immediate owner is a token (`true`) or not (`false`)
     */
    function directOwnerOf(
        uint256 tokenId
    ) public view virtual returns (address, uint256, bool) {
        DirectOwner memory owner = _directOwners[tokenId];
        if (owner.ownerAddress == address(0)) revert ERC721InvalidTokenId();

        return (owner.ownerAddress, owner.tokenId, owner.isNft);
    }

    /**
     * @notice Used to retrieve the active child tokens of a given parent token.
     * @dev Returns array of Child structs existing for parent token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param parentId ID of the parent token for which to retrieve the active child tokens
     * @return struct[] An array of Child structs containing the parent token's active child tokens
     */

    function childrenOf(
        uint256 parentId
    ) public view virtual returns (Child[] memory) {
        Child[] memory children = _activeChildren[parentId];
        return children;
    }

    /**
     * @notice Used to retrieve the pending child tokens of a given parent token.
     * @dev Returns array of pending Child structs existing for given parent.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param parentId ID of the parent token for which to retrieve the pending child tokens
     * @return struct[] An array of Child structs containing the parent token's pending child tokens
     */

    function pendingChildrenOf(
        uint256 parentId
    ) public view virtual returns (Child[] memory) {
        Child[] memory pendingChildren = _pendingChildren[parentId];
        return pendingChildren;
    }

    /**
     * @notice Used to retrieve a specific active child token for a given parent token.
     * @dev Returns a single Child struct locating at `index` of parent token's active child tokens array.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param parentId ID of the parent token for which the child is being retrieved
     * @param index Index of the child token in the parent token's active child tokens array
     * @return struct A Child struct containing data about the specified child
     */
    function childOf(
        uint256 parentId,
        uint256 index
    ) public view virtual returns (Child memory) {
        if (childrenOf(parentId).length <= index) revert ChildIndexOutOfRange();
        Child memory child = _activeChildren[parentId][index];
        return child;
    }

    /**
     * @notice Used to retrieve a specific pending child token from a given parent token.
     * @dev Returns a single Child struct locating at `index` of parent token's active child tokens array.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param parentId ID of the parent token for which the pending child token is being retrieved
     * @param index Index of the child token in the parent token's pending child tokens array
     * @return struct A Child struct containting data about the specified child
     */
    function pendingChildOf(
        uint256 parentId,
        uint256 index
    ) public view virtual returns (Child memory) {
        if (pendingChildrenOf(parentId).length <= index)
            revert PendingChildIndexOutOfRange();
        Child memory child = _pendingChildren[parentId][index];
        return child;
    }

    /**
     * @notice Used to verify that the given child tokwn is included in an active array of a token.
     * @param childAddress Address of the given token's collection smart contract
     * @param childId ID of the child token being checked
     * @return bool A boolean value signifying whether the given child token is included in an active child tokens array
     *  of a token (`true`) or not (`false`)
     */
    function childIsInActive(
        address childAddress,
        uint256 childId
    ) public view virtual returns (bool) {
        return _childIsInActive[childAddress][childId] != 0;
    }

    // --------------------- NESTABLE SETTERS ---------------------
    /**
     * @notice Used to add a child token to a given parent token.
     * @dev This adds the iichild token into the given parent token's pending child tokens array.
     * @dev You MUST NOT call this method directly. To add a a child to an NFT you must use either
     *  `nestTransfer`, `nestMint` or `transferChild` to the NFT.
     * @dev Requirements:
     *
     *  - `ownerOf` on the child contract must resolve to the called contract.
     *  - The pending array of the parent contract must not be full.
     * @param parentId ID of the parent token to receive the new child token
     * @param childId ID of the new proposed child token
     * @param data Additional data with no specified format
     */
    function addChild(
        uint256 parentId,
        uint256 childId,
        bytes memory data
    ) public virtual {
        _requireMinted(parentId);

        address childAddress = _msgSender();
        if (!childAddress.isContract()) revert IsNotContract();

        Child memory child = Child({
            contractAddress: childAddress,
            tokenId: childId
        });

        _beforeAddChild(parentId, childAddress, childId);

        uint256 length = pendingChildrenOf(parentId).length;

        if (length < 128) {
            _pendingChildren[parentId].push(child);
        } else {
            revert MaxPendingChildrenReached();
        }

        // Previous length matches the index for the new child
        emit ChildProposed(parentId, length, childAddress, childId);

        _afterAddChild(parentId, childAddress, childId);
    }

    /**
     * @notice @notice Used to accept a pending child token for a given parent token.
     * @dev This moves the child token from parent token's pending child tokens array into the active child tokens
     *  array.
     * @param parentId ID of the parent token for which the child token is being accepted
     * @param childIndex Index of a child tokem in the given parent's pending children array
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     */
    function acceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) public virtual onlyApprovedOrOwner(parentId) {
        _acceptChild(parentId, childIndex, childAddress, childId);
    }

    /**
     * @notice Used to reject all pending children of a given parent token.
     * @dev Removes the children from the pending array mapping.
     * @dev This does not update the ownership storage data on children. If necessary, ownership can be reclaimed by the
     *  rootOwner of the previous parent.
     * @param tokenId ID of the parent token for which to reject all of the pending tokens
     */
    function rejectAllChildren(
        uint256 tokenId,
        uint256 maxRejections
    ) public virtual onlyApprovedOrOwner(tokenId) {
        _rejectAllChildren(tokenId, maxRejections);
    }

    /**
     * @notice Used to transfer a child token from a given parent token.
     * @param tokenId ID of the parent token from which the child token is being transferred
     * @param to Address to which to transfer the token to
     * @param destinationId ID of the token to receive this child token (MUST be 0 if the destination is not a token)
     * @param childIndex Index of a token we are transferring, in the array it belongs to (can be either active array or
     *  pending array)
     * @param childAddress Address of the child token's collection smart contract.
     * @param childId ID of the child token in its own collection smart contract.
     * @param isPending A boolean value indicating whether the child token being transferred is in the pending array of the
     *  parent token (`true`) or in the active array (`false`)
     * @param data Additional data with no specified format, sent in call to `_to`
     */
    function transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) public virtual onlyApprovedOrOwner(tokenId) {
        _transferChild(
            tokenId,
            to,
            destinationId,
            childIndex,
            childAddress,
            childId,
            isPending,
            data
        );
    }

    /**
     * @notice Used to transfer the token into another token.
     * @dev The destination token MUST NOT be a child token of the token being transferred or one of its downstream
     *  child tokens.
     * @param from Address of the direct owner of the token to be transferred
     * @param to Address of the receiving token's collection smart contract
     * @param tokenId ID of the token being transferred
     * @param destinationId ID of the token to receive the token being transferred
     */
    function nestTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _nestTransfer(from, to, tokenId, destinationId, data);
    }

    // --------------------- NESTABLE INTERNAL ---------------------

    /**
     * @notice Used to transfer a child token from a given parent token.
     * @dev When transferring a child token, the owner of the token is set to `to`, or is not updated in the event of `to`
     *  being the `0x0` address.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @dev Emits {ChildTransferred} event.
     * @param tokenId ID of the parent token from which the child token is being transferred
     * @param to Address to which to transfer the token to
     * @param destinationId ID of the token to receive this child token (MUST be 0 if the destination is not a token)
     * @param childIndex Index of a token we are transferring, in the array it belongs to (can be either active array or
     *  pending array)
     * @param childAddress Address of the child token's collection smart contract.
     * @param childId ID of the child token in its own collection smart contract.
     * @param isPending A boolean value indicating whether the child token being transferred is in the pending array of the
     *  parent token (`true`) or in the active array (`false`)
     * @param data Additional data with no specified format, sent in call to `_to`
     */
    function _transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId, // newParentId
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) internal virtual {
        Child memory child;
        if (!isPending) {
            if (isChildEquipped(tokenId, childAddress, childId))
                revert MustUnequipFirst();
        }
        if (isPending) {
            child = pendingChildOf(tokenId, childIndex);
        } else {
            child = childOf(tokenId, childIndex);
        }
        _checkExpectedChild(child, childAddress, childId);

        _beforeTransferChild(
            tokenId,
            childIndex,
            childAddress,
            childId,
            isPending
        );

        if (isPending) {
            _removeChildByIndex(_pendingChildren[tokenId], childIndex);
        } else {
            delete _childIsInActive[childAddress][childId];
            _removeChildByIndex(_activeChildren[tokenId], childIndex);
        }

        if (to != address(0)) {
            if (destinationId == 0) {
                IERC721(childAddress).safeTransferFrom(
                    address(this),
                    to,
                    childId,
                    data
                );
            } else {
                // Destination is an NFT
                IERC6059(child.contractAddress).nestTransferFrom(
                    address(this),
                    to,
                    child.tokenId,
                    destinationId,
                    data
                );
            }
        }

        emit ChildTransferred(
            tokenId,
            childIndex,
            childAddress,
            childId,
            isPending
        );
        _afterTransferChild(
            tokenId,
            childIndex,
            childAddress,
            childId,
            isPending
        );
    }

    /**
     * @notice Used to accept a pending child token for a given parent token.
     * @dev This moves the child token from parent token's pending child tokens array into the active child tokens
     *  array.
     * @dev Requirements:
     *
     *  - `tokenId` must exist
     *  - `index` must be in range of the pending children array
     * @param parentId ID of the parent token for which the child token is being accepted
     * @param childIndex Index of a child tokem in the given parent's pending children array
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     */
    function _acceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) internal virtual {
        if (pendingChildrenOf(parentId).length <= childIndex)
            revert PendingChildIndexOutOfRange();

        Child memory child = pendingChildOf(parentId, childIndex);
        _checkExpectedChild(child, childAddress, childId);
        if (_childIsInActive[childAddress][childId] != 0)
            revert ChildAlreadyExists();

        _beforeAcceptChild(parentId, childIndex, childAddress, childId);

        // Remove from pending:
        _removeChildByIndex(_pendingChildren[parentId], childIndex);

        // Add to active:
        _activeChildren[parentId].push(child);
        _childIsInActive[childAddress][childId] = 1; // We use 1 as true

        emit ChildAccepted(parentId, childIndex, childAddress, childId);

        _afterAcceptChild(parentId, childIndex, childAddress, childId);
    }

    /**
     * @notice Used to reject all pending children of a given parent token.
     * @dev Removes the children from the pending array mapping.
     * @dev This does not update the ownership storage data on children. If necessary, ownership can be reclaimed by the
     *  rootOwner of the previous parent.
     * @dev Requirements:
     *
     *  - `tokenId` must exist
     * @param tokenId ID of the parent token for which to reject all of the pending tokens.
     * @param maxRejections Maximum number of expected children to reject, used to prevent from
     *  rejecting children which arrive just before this operation.
     */
    function _rejectAllChildren(
        uint256 tokenId,
        uint256 maxRejections
    ) internal virtual {
        if (_pendingChildren[tokenId].length > maxRejections)
            revert UnexpectedNumberOfChildren();

        _beforeRejectAllChildren(tokenId);
        delete _pendingChildren[tokenId];
        emit AllChildrenRejected(tokenId);
        _afterRejectAllChildren(tokenId);
    }

    function _checkExpectedChild(
        Child memory child,
        address expectedAddress,
        uint256 expectedId
    ) private pure {
        if (
            expectedAddress != child.contractAddress ||
            expectedId != child.tokenId
        ) revert UnexpectedChildId();
    }

    /**
     * @notice Used to remove a specified child token form an array using its index within said array.
     * @dev The caller must ensure that the length of the array is valid compared to the index passed.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param array An array od Child struct containing info about the child tokens in a given child tokens array
     * @param index An index of the child token to remove in the accompanying array
     */
    function _removeChildByIndex(Child[] storage array, uint256 index) private {
        array[index] = array[array.length - 1];
        array.pop();
    }

    /**
     * @notice Used to transfer a token into another token.
     * @dev Attempting to nest a token into `0x0` address will result in reverted transaction.
     * @dev Attempting to nest a token into itself will result in reverted transaction.
     * @param from Address of the account currently owning the given token
     * @param to Address of the receiving token's collection smart contract
     * @param tokenId ID of the token to transfer
     * @param destinationId ID of the token receiving the given token
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _nestTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) internal virtual {
        (address immediateOwner, uint256 parentId, ) = directOwnerOf(tokenId);
        if (immediateOwner != from) revert ERC721TransferFromIncorrectOwner();
        if (to == address(0)) revert ERC721TransferToTheZeroAddress();
        if (to == address(this) && tokenId == destinationId)
            revert NestableTransferToSelf();

        // Destination contract checks:
        // It seems redundant, but otherwise it would revert with no error
        if (!to.isContract()) revert IsNotContract();
        if (!IERC165(to).supportsInterface(type(IERC6059).interfaceId))
            revert NestableTransferToNonNestableImplementer();
        _checkForInheritanceLoop(tokenId, to, destinationId);

        _beforeTokenTransfer(from, to, tokenId);
        _beforeNestedTokenTransfer(
            immediateOwner,
            to,
            parentId,
            destinationId,
            tokenId
        );
        _balances[from] -= 1;
        _updateOwnerAndClearApprovals(tokenId, destinationId, to, true);
        _balances[to] += 1;

        // Sending to NFT:
        _sendToNFT(immediateOwner, to, parentId, destinationId, tokenId, data);
    }

    /**
     * @notice Used to send a token to another token.
     * @dev If the token being sent is currently owned by an externally owned account, the `parentId` should equal `0`.
     * @dev Emits {Transfer} event.
     * @dev Emits {NestTransfer} event.
     * @param from Address from which the token is being sent
     * @param to Address of the collection smart contract of the token to receive the given token
     * @param parentId ID of the current parent token of the token being sent
     * @param destinationId ID of the tokento receive the token being sent
     * @param tokenId ID of the token being sent
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _sendToNFT(
        address from,
        address to,
        uint256 parentId,
        uint256 destinationId,
        uint256 tokenId,
        bytes memory data
    ) private {
        IERC6059 destContract = IERC6059(to);
        destContract.addChild(destinationId, tokenId, data);
        _afterTokenTransfer(from, to, tokenId);
        _afterNestedTokenTransfer(from, to, parentId, destinationId, tokenId);

        emit Transfer(from, to, tokenId);
        emit NestTransfer(from, to, parentId, destinationId, tokenId);
    }

    /**
     * @notice Used to check if nesting a given token into a specified token would create an inheritance loop.
     * @dev If a loop would occur, the tokens would be unmanageable, so the execution is reverted if one is detected.
     * @dev The check for inheritance loop is bounded to guard against too much gas being consumed.
     * @param currentId ID of the token that would be nested
     * @param targetContract Address of the collection smart contract of the token into which the given token would be
     *  nested
     * @param targetId ID of the token into which the given token would be nested
     */
    function _checkForInheritanceLoop(
        uint256 currentId,
        address targetContract,
        uint256 targetId
    ) private view {
        for (uint256 i; i < _MAX_LEVELS_TO_CHECK_FOR_INHERITANCE_LOOP; ) {
            (
                address nextOwner,
                uint256 nextOwnerTokenId,
                bool isNft
            ) = IERC6059(targetContract).directOwnerOf(targetId);
            // If there's a final address, we're good. There's no loop.
            if (!isNft) {
                return;
            }
            // Ff the current nft is an ancestor at some point, there is an inheritance loop
            if (nextOwner == address(this) && nextOwnerTokenId == currentId) {
                revert NestableTransferToDescendant();
            }
            // We reuse the parameters to save some contract size
            targetContract = nextOwner;
            targetId = nextOwnerTokenId;
            unchecked {
                ++i;
            }
        }
        revert NestableTooDeep();
    }

    // --------------------- MULTIASSET GETTERS ---------------------

    /**
     * @notice Used to get the address of the user that is approved to manage the specified token from the current
     *  owner.
     * @param tokenId ID of the token we are checking
     * @return address Address of the account that is approved to manage the token
     */
    function getApprovedForAssets(
        uint256 tokenId
    ) public view virtual returns (address) {
        _requireMinted(tokenId);
        return _tokenApprovalsForAssets[tokenId][ownerOf(tokenId)];
    }

    /**
     * @inheritdoc IERC5773
     */
    function getAssetMetadata(
        uint256 tokenId,
        uint64 assetId
    ) public view virtual returns (string memory) {
        if (!_tokenAssets[tokenId][assetId]) revert TokenDoesNotHaveAsset();
        return _assets[assetId];
    }

    /**
     * @inheritdoc IERC5773
     */
    function getActiveAssets(
        uint256 tokenId
    ) public view virtual returns (uint64[] memory) {
        return _activeAssets[tokenId];
    }

    /**
     * @inheritdoc IERC5773
     */
    function getPendingAssets(
        uint256 tokenId
    ) public view virtual returns (uint64[] memory) {
        return _pendingAssets[tokenId];
    }

    /**
     * @inheritdoc IERC5773
     */
    function getActiveAssetPriorities(
        uint256 tokenId
    ) public view virtual returns (uint16[] memory) {
        return _activeAssetPriorities[tokenId];
    }

    /**
     * @inheritdoc IERC5773
     */
    function getAssetReplacements(
        uint256 tokenId,
        uint64 newAssetId
    ) public view virtual returns (uint64) {
        return _assetReplacements[tokenId][newAssetId];
    }

    /**
     * @inheritdoc IERC5773
     */
    function isApprovedForAllForAssets(
        address owner,
        address operator
    ) public view virtual returns (bool) {
        return _operatorApprovalsForAssets[owner][operator];
    }

    // --------------------- MULTIASSET SETTERS ---------------------
    /**
     * @notice Used to grant approvals for specific tokens to a specified address.
     * @dev This can only be called by the owner of the token or by an account that has been granted permission to
     *  manage all of the owner's assets.
     * @param to Address of the account to receive the approval to the specified token
     * @param tokenId ID of the token for which we are granting the permission
     */
    function approveForAssets(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ApprovalForAssetsToCurrentOwner();

        if (
            _msgSender() != owner &&
            !isApprovedForAllForAssets(owner, _msgSender())
        ) revert ApproveForAssetsCallerIsNotOwnerNorApprovedForAll();
        _approveForAssets(to, tokenId);
    }

    /**
     * @inheritdoc IERC5773
     */
    function setApprovalForAllForAssets(
        address operator,
        bool approved
    ) public virtual {
        address owner = _msgSender();
        if (owner == operator) revert ApprovalForAssetsToCurrentOwner();

        _operatorApprovalsForAssets[owner][operator] = approved;
        emit ApprovalForAllForAssets(owner, operator, approved);
    }

    /**
     * @notice Accepts a asset at from the pending array of given token.
     * @dev Migrates the asset from the token's pending asset array to the token's active asset array.
     * @dev Active assets cannot be removed by anyone, but can be replaced by a new asset.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - `index` must be in range of the length of the pending asset array.
     * @dev Emits an {AssetAccepted} event.
     * @param tokenId ID of the token for which to accept the pending asset
     * @param index Index of the asset in the pending array to accept
     */
    function acceptAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) public virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _acceptAsset(tokenId, index, assetId);
    }

    /**
     * @notice Rejects a asset from the pending array of given token.
     * @dev Removes the asset from the token's pending asset array.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - `index` must be in range of the length of the pending asset array.
     * @dev Emits a {AssetRejected} event.
     * @param tokenId ID of the token that the asset is being rejected from
     * @param index Index of the asset in the pending array to be rejected
     */
    function rejectAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) public virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _rejectAsset(tokenId, index, assetId);
    }

    /**
     * @notice Rejects all assets from the pending array of a given token.
     * @dev Effecitvely deletes the pending array.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     * @dev Emits a {AssetRejected} event with assetId = 0.
     * @param tokenId ID of the token of which to clear the pending array.
     * @param maxRejections Maximum number of expected assets to reject, used to prevent from rejecting assets which
     *  arrive just before this operation.
     */
    function rejectAllAssets(
        uint256 tokenId,
        uint256 maxRejections
    ) public virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _rejectAllAssets(tokenId, maxRejections);
    }

    /**
     * @notice Sets a new priority array for a given token.
     * @dev The priority array is a non-sequential list of `uint16`s, where the lowest value is considered highest
     *  priority.
     * @dev Value `0` of a priority is a special case equivalent to unitialized.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - The length of `priorities` must be equal the length of the active assets array.
     * @dev Emits a {AssetPrioritySet} event.
     * @param tokenId ID of the token to set the priorities for
     * @param priorities An array of priority values
     */
    function setPriority(
        uint256 tokenId,
        uint16[] calldata priorities
    ) public virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _setPriority(tokenId, priorities);
    }

    // --------------------- MULTIASSET INTERNAL ---------------------

    /**
     * @notice Internal function for granting approvals for a specific token.
     * @param to Address of the account we are granting an approval to
     * @param tokenId ID of the token we are granting the approval for
     */
    function _approveForAssets(address to, uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        _tokenApprovalsForAssets[tokenId][owner] = to;
        emit ApprovalForAssets(owner, to, tokenId);
    }

    /**
     * @notice Used to add a asset entry.
     * @dev This internal function warrants custom access control to be implemented when used.
     * @param id ID of the asset being added
     * @param equippableGroupId ID of the equippable group being marked as equippable into the slot associated with
     *  `Parts` of the `Slot` type
     * @param catalogAddress Address of the `Catalog` associated with the asset
     * @param metadataURI The metadata URI of the asset
     * @param partIds An array of IDs of fixed and slot parts to be included in the asset
     */
    function _addAssetEntry(
        uint64 id,
        uint64 equippableGroupId,
        address catalogAddress,
        string memory metadataURI,
        uint64[] calldata partIds
    ) internal virtual {
        _addAssetEntry(id, metadataURI);

        if (catalogAddress == address(0) && partIds.length != 0)
            revert CatalogRequiredForParts();

        _catalogAddresses[id] = catalogAddress;
        _equippableGroupIds[id] = equippableGroupId;
        _partIds[id] = partIds;
    }

    /**
     * @notice Used to accept a pending asset.
     * @dev The call is reverted if there is no pending asset at a given index.
     * @param tokenId ID of the token for which to accept the pending asset
     * @param index Index of the asset in the pending array to accept
     * @param assetId ID of the asset to accept in token's pending array
     */
    function _acceptAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) internal virtual {
        _validatePendingAssetAtIndex(tokenId, index, assetId);
        _beforeAcceptAsset(tokenId, index, assetId);

        uint64 replacesId = _assetReplacements[tokenId][assetId];
        uint256 replaceIndex;
        bool replacefound;
        if (replacesId != uint64(0))
            (replaceIndex, replacefound) = _activeAssets[tokenId].indexOf(
                replacesId
            );

        if (replacefound) {
            // We don't want to remove and then push a new asset.
            // This way we also keep the priority of the original asset
            _activeAssets[tokenId][replaceIndex] = assetId;
            delete _tokenAssets[tokenId][replacesId];
        } else {
            // We use the current size as next priority, by default priorities would be [0,1,2...]
            _activeAssetPriorities[tokenId].push(
                uint16(_activeAssets[tokenId].length)
            );
            _activeAssets[tokenId].push(assetId);
            replacesId = uint64(0);
        }
        _removePendingAsset(tokenId, index, assetId);

        emit AssetAccepted(tokenId, assetId, replacesId);
        _afterAcceptAsset(tokenId, index, assetId);
    }

    /**
     * @notice Used to reject the specified asset from the pending array.
     * @dev The call is reverted if there is no pending asset at a given index.
     * @param tokenId ID of the token that the asset is being rejected from
     * @param index Index of the asset in the pending array to be rejected
     * @param assetId ID of the asset expected to be in the index
     */
    function _rejectAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) internal virtual {
        _validatePendingAssetAtIndex(tokenId, index, assetId);
        _beforeRejectAsset(tokenId, index, assetId);

        _removePendingAsset(tokenId, index, assetId);
        delete _tokenAssets[tokenId][assetId];

        emit AssetRejected(tokenId, assetId);
        _afterRejectAsset(tokenId, index, assetId);
    }

    /**
     * @notice Used to validate the index on the pending assets array
     * @dev The call is reverted if the index is out of range or the asset Id is not present at the index.
     * @param tokenId ID of the token that the asset is validated from
     * @param index Index of the asset in the pending array
     * @param assetId Id of the asset expected to be in the index
     */
    function _validatePendingAssetAtIndex(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) private view {
        if (index >= _pendingAssets[tokenId].length) revert IndexOutOfRange();
        if (assetId != _pendingAssets[tokenId][index])
            revert UnexpectedAssetId();
    }

    /**
     * @notice Used to remove the asset at the index on the pending assets array
     * @param tokenId ID of the token that the asset is being removed from
     * @param index Index of the asset in the pending array
     * @param assetId Id of the asset expected to be in the index
     */
    function _removePendingAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) private {
        _pendingAssets[tokenId].removeItemByIndex(index);
        delete _assetReplacements[tokenId][assetId];
    }

    /**
     * @notice Used to reject all of the pending assets for the given token.
     * @dev When rejecting all assets, the pending array is indiscriminately cleared.
     * @dev If the number of pending assets is greater than the value of `maxRejections`, the exectuion will be
     *  reverted.
     * @param tokenId ID of the token to reject all of the pending assets.
     * @param maxRejections Maximum number of expected assets to reject, used to prevent from
     *  rejecting assets which arrive just before this operation.
     */
    function _rejectAllAssets(
        uint256 tokenId,
        uint256 maxRejections
    ) internal virtual {
        uint256 len = _pendingAssets[tokenId].length;
        if (len > maxRejections) revert UnexpectedNumberOfAssets();

        _beforeRejectAllAssets(tokenId);

        for (uint256 i; i < len; ) {
            uint64 assetId = _pendingAssets[tokenId][i];
            delete _assetReplacements[tokenId][assetId];
            unchecked {
                ++i;
            }
        }
        delete (_pendingAssets[tokenId]);

        emit AssetRejected(tokenId, uint64(0));
        _afterRejectAllAssets(tokenId);
    }

    /**
     * @notice Used to specify the priorities for a given token's active assets.
     * @dev If the length of the priorities array doesn't match the length of the active assets array, the execution
     *  will be reverted.
     * @dev The position of the priority value in the array corresponds the position of the asset in the active
     *  assets array it will be applied to.
     * @param tokenId ID of the token for which the priorities are being set
     * @param priorities Array of priorities for the assets
     */
    function _setPriority(
        uint256 tokenId,
        uint16[] calldata priorities
    ) internal virtual {
        uint256 length = priorities.length;
        if (length != _activeAssets[tokenId].length)
            revert BadPriorityListLength();

        _beforeSetPriority(tokenId, priorities);
        _activeAssetPriorities[tokenId] = priorities;

        emit AssetPrioritySet(tokenId);
        _afterSetPriority(tokenId, priorities);
    }

    /**
     * @notice Used to add an asset entry.
     * @dev If the specified ID is already used by another asset, the execution will be reverted.
     * @dev This internal function warrants custom access control to be implemented when used.
     * @param id ID of the asset to assign to the new asset
     * @param metadataURI Metadata URI of the asset
     */
    function _addAssetEntry(
        uint64 id,
        string memory metadataURI
    ) internal virtual {
        if (id == uint64(0)) revert IdZeroForbidden();
        if (bytes(_assets[id]).length > 0) revert AssetAlreadyExists();

        _beforeAddAsset(id, metadataURI);
        _assets[id] = metadataURI;

        emit AssetSet(id);
        _afterAddAsset(id, metadataURI);
    }

    /**
     * @notice Used to add an asset to a token.
     * @dev If the given asset is already added to the token, the execution will be reverted.
     * @dev If the asset ID is invalid, the execution will be reverted.
     * @dev If the token already has the maximum amount of pending assets (128), the execution will be
     *  reverted.
     * @param tokenId ID of the token to add the asset to
     * @param assetId ID of the asset to add to the token
     * @param replacesAssetWithId ID of the asset to replace from the token's list of active assets
     */
    function _addAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 replacesAssetWithId
    ) internal virtual {
        if (_tokenAssets[tokenId][assetId]) revert AssetAlreadyExists();

        if (bytes(_assets[assetId]).length == 0) revert NoAssetMatchingId();

        if (_pendingAssets[tokenId].length >= 128)
            revert MaxPendingAssetsReached();

        _beforeAddAssetToToken(tokenId, assetId, replacesAssetWithId);
        _tokenAssets[tokenId][assetId] = true;
        _pendingAssets[tokenId].push(assetId);

        if (replacesAssetWithId != uint64(0)) {
            _assetReplacements[tokenId][assetId] = replacesAssetWithId;
        }

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        emit AssetAddedToTokens(tokenIds, assetId, replacesAssetWithId);
        _afterAddAssetToToken(tokenId, assetId, replacesAssetWithId);
    }

    // --------------------- EQUIPPABLE GETTERS ---------------------

    /**
     * @inheritdoc IERC6220
     */
    function canTokenBeEquippedWithAssetIntoSlot(
        address parent,
        uint256 tokenId,
        uint64 assetId,
        uint64 slotId
    ) public view virtual returns (bool) {
        uint64 equippableGroupId = _equippableGroupIds[assetId];
        uint64 equippableSlot = _validParentSlots[equippableGroupId][parent];
        if (equippableSlot == slotId) {
            (, bool found) = getActiveAssets(tokenId).indexOf(assetId);
            return found;
        }
        return false;
    }

    /**
     * @inheritdoc IERC6220
     */
    function isChildEquipped(
        uint256 tokenId,
        address childAddress,
        uint256 childId
    ) public view virtual returns (bool) {
        return _equipCountPerChild[tokenId][childAddress][childId] != uint8(0);
    }

    /**
     * @inheritdoc IERC6220
     */
    function getAssetAndEquippableData(
        uint256 tokenId,
        uint64 assetId
    )
        public
        view
        virtual
        returns (string memory, uint64, address, uint64[] memory)
    {
        return (
            getAssetMetadata(tokenId, assetId),
            _equippableGroupIds[assetId],
            _catalogAddresses[assetId],
            _partIds[assetId]
        );
    }

    /**
     * @inheritdoc IERC6220
     */
    function getEquipment(
        uint256 tokenId,
        address targetCatalogAddress,
        uint64 slotPartId
    ) public view virtual returns (Equipment memory) {
        return _equipments[tokenId][targetCatalogAddress][slotPartId];
    }

    // --------------------- EQUIPPABLE SETTERS ---------------------

    /**
     * @inheritdoc IERC6220
     */
    function equip(
        IntakeEquip memory data
    ) public virtual onlyApprovedOrOwner(data.tokenId) {
        _equip(data);
    }

    /**
     * @inheritdoc IERC6220
     */
    function unequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) public virtual onlyApprovedOrOwner(tokenId) {
        _unequip(tokenId, assetId, slotPartId);
    }

    // --------------------- EQUIPPABLE INTERNAL ---------------------

    /**
     * @notice Private function used to equip a child into a token.
     * @dev If the `Slot` already has an item equipped, the execution will be reverted.
     * @dev If the child can't be used in the given `Slot`, the execution will be reverted.
     * @dev If the catalog doesn't allow this equip to happen, the execution will be reverted.
     * @dev The `IntakeEquip` stuct contains the following data:
     *  [
     *      tokenId,
     *      childIndex,
     *      assetId,
     *      slotPartId,
     *      childAssetId
     *  ]
     * @param data An `IntakeEquip` struct specifying the equip data
     */
    function _equip(IntakeEquip memory data) internal virtual {
        address catalogAddress = _catalogAddresses[data.assetId];
        uint64 slotPartId = data.slotPartId;
        if (
            _equipments[data.tokenId][catalogAddress][slotPartId]
                .childEquippableAddress != address(0)
        ) revert SlotAlreadyUsed();

        // Check from parent's asset perspective:
        (, bool found) = _partIds[data.assetId].indexOf(slotPartId);
        if (!found) revert TargetAssetCannotReceiveSlot();

        IERC6059.Child memory child = childOf(data.tokenId, data.childIndex);

        // Check from child perspective intention to be used in part
        // We add reentrancy guard because of this call, it happens before updating state
        if (
            !IERC6220(child.contractAddress)
                .canTokenBeEquippedWithAssetIntoSlot(
                    address(this),
                    child.tokenId,
                    data.childAssetId,
                    slotPartId
                )
        ) revert TokenCannotBeEquippedWithAssetIntoSlot();

        // Check from catalog perspective
        if (
            !ICatalog(catalogAddress).checkIsEquippable(
                slotPartId,
                child.contractAddress
            )
        ) revert EquippableEquipNotAllowedByCatalog();

        _beforeEquip(data);
        Equipment memory newEquip = Equipment({
            assetId: data.assetId,
            childAssetId: data.childAssetId,
            childId: child.tokenId,
            childEquippableAddress: child.contractAddress
        });

        _equipments[data.tokenId][catalogAddress][slotPartId] = newEquip;
        _equipCountPerChild[data.tokenId][child.contractAddress][
            child.tokenId
        ] += 1;

        emit ChildAssetEquipped(
            data.tokenId,
            data.assetId,
            slotPartId,
            child.tokenId,
            child.contractAddress,
            data.childAssetId
        );
        _afterEquip(data);
    }

    /**
     * @notice Private function used to unequip child from parent token.
     * @param tokenId ID of the parent from which the child is being unequipped
     * @param assetId ID of the parent's asset that contains the `Slot` into which the child is equipped
     * @param slotPartId ID of the `Slot` from which to unequip the child
     */
    function _unequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) internal virtual {
        address targetCatalogAddress = _catalogAddresses[assetId];
        Equipment memory equipment = _equipments[tokenId][targetCatalogAddress][
            slotPartId
        ];
        if (equipment.childEquippableAddress == address(0))
            revert NotEquipped();
        _beforeUnequip(tokenId, assetId, slotPartId);

        delete _equipments[tokenId][targetCatalogAddress][slotPartId];
        _equipCountPerChild[tokenId][equipment.childEquippableAddress][
            equipment.childId
        ] -= 1;

        emit ChildAssetUnequipped(
            tokenId,
            assetId,
            slotPartId,
            equipment.childId,
            equipment.childEquippableAddress,
            equipment.childAssetId
        );
        _afterUnequip(tokenId, assetId, slotPartId);
    }

    /**
     * @notice Internal function used to declare that the assets belonging to a given `equippableGroupId` are
     *  equippable into the `Slot` associated with the `partId` of the collection at the specified `parentAddress`
     * @param equippableGroupId ID of the equippable group
     * @param parentAddress Address of the parent into which the equippable group can be equipped into
     * @param slotPartId ID of the `Slot` that the items belonging to the equippable group can be equipped into
     */
    function _setValidParentForEquippableGroup(
        uint64 equippableGroupId,
        address parentAddress,
        uint64 slotPartId
    ) internal virtual {
        if (equippableGroupId == uint64(0) || slotPartId == uint64(0))
            revert IdZeroForbidden();
        _validParentSlots[equippableGroupId][parentAddress] = slotPartId;
        emit ValidParentEquippableGroupIdSet(
            equippableGroupId,
            slotPartId,
            parentAddress
        );
    }

    // --------------------- MODIFIERS IMPLEMENTATIONS ---------------------

    /**
     * @notice Used to verify that the caller is either the owner of the token or approved to manage it by its owner.
     * @dev If the caller is not the owner of the token or approved to manage it by its owner, the execution will be
     *  reverted.
     * @param tokenId ID of the token to check
     */
    function _onlyApprovedOrOwner(uint256 tokenId) private view {
        if (!_isApprovedOrOwner(_msgSender(), tokenId))
            revert ERC721NotApprovedOrOwner();
    }

    /**
     * @notice Used to verify that the caller is approved to manage the given token or it its direct owner.
     * @dev This does not delegate to ownerOf, which returns the root owner, but rater uses an owner from DirectOwner
     *  struct.
     * @dev The execution is reverted if the caller is not immediate owner or approved to manage the given token.
     * @dev Used for parent-scoped transfers.
     * @param tokenId ID of the token to check.
     */
    function _onlyApprovedOrDirectOwner(uint256 tokenId) private view {
        if (!_isApprovedOrDirectOwner(_msgSender(), tokenId))
            revert NotApprovedOrDirectOwner();
    }

    /**
     * @notice Used to verify that the caller is either the owner of the given token or approved to manage the token's assets
     *  of the owner.
     * @param tokenId ID of the token that we are checking
     */
    function _onlyApprovedForAssetsOrOwner(uint256 tokenId) private view {
        if (!_isApprovedForAssetsOrOwner(_msgSender(), tokenId))
            revert NotApprovedForAssetsOrOwner();
    }

    /**
     * @notice Used to check whether the given account is allowed to manage the given token.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @param spender Address that is being checked for approval
     * @param tokenId ID of the token being checked
     * @return bool The boolean value indicating whether the `spender` is approved to manage the given token
     */
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @notice Used to check whether the account is approved to manage the token or its direct owner.
     * @param spender Address that is being checked for approval or direct ownership
     * @param tokenId ID of the token being checked
     * @return bool The boolean value indicating whether the `spender` is approved to manage the given token or its
     *  direct owner
     */
    function _isApprovedOrDirectOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        (address owner, uint256 parentId, ) = directOwnerOf(tokenId);
        // When the parent is an NFT, only it can do operations
        if (parentId != 0) {
            return (spender == owner);
        }
        // Otherwise, the owner or approved address can
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @notice Internal function to check whether the queried user is either:
     *   1. The root owner of the token associated with `tokenId`.
     *   2. Is approved for all assets of the current owner via the `setApprovalForAllForAssets` function.
     *   3. Is granted approval for the specific tokenId for asset management via the `approveForAssets` function.
     * @param user Address of the user we are checking for permission
     * @param tokenId ID of the token to query for permission for a given `user`
     * @return bool A boolean value indicating whether the user is approved to manage the token or not
     */
    function _isApprovedForAssetsOrOwner(
        address user,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (user == owner ||
            isApprovedForAllForAssets(owner, user) ||
            getApprovedForAssets(tokenId) == user);
    }

    // --------------------- MULTIASSET HOOKS ---------------------

    /**
     * @notice Hook that is called before an asset is added.
     * @param id ID of the asset
     * @param metadataURI Metadata URI of the asset
     */
    function _beforeAddAsset(
        uint64 id,
        string memory metadataURI
    ) internal virtual {}

    /**
     * @notice Hook that is called after an asset is added.
     * @param id ID of the asset
     * @param metadataURI Metadata URI of the asset
     */
    function _afterAddAsset(
        uint64 id,
        string memory metadataURI
    ) internal virtual {}

    /**
     * @notice Hook that is called before adding an asset to a token's pending assets array.
     * @dev If the asset doesn't intend to replace another asset, the `replacesAssetWithId` value should be `0`.
     * @param tokenId ID of the token to which the asset is being added
     * @param assetId ID of the asset that is being added
     * @param replacesAssetWithId ID of the asset that this asset is attempting to replace
     */
    function _beforeAddAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 replacesAssetWithId
    ) internal virtual {}

    /**
     * @notice Hook that is called after an asset has been added to a token's pending assets array.
     * @dev If the asset doesn't intend to replace another asset, the `replacesAssetWithId` value should be `0`.
     * @param tokenId ID of the token to which the asset is has been added
     * @param assetId ID of the asset that is has been added
     * @param replacesAssetWithId ID of the asset that this asset is attempting to replace
     */
    function _afterAddAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 replacesAssetWithId
    ) internal virtual {}

    /**
     * @notice Hook that is called before an asset is accepted to a token's active assets array.
     * @param tokenId ID of the token for which the asset is being accepted
     * @param index Index of the asset in the token's pending assets array
     * @param assetId ID of the asset expected to be located at the specified `index`
     */
    function _beforeAcceptAsset(
        uint256 tokenId,
        uint256 index,
        uint256 assetId
    ) internal virtual {}

    /**
     * @notice Hook that is called after an asset is accepted to a token's active assets array.
     * @param tokenId ID of the token for which the asset has been accepted
     * @param index Index of the asset in the token's pending assets array
     * @param assetId ID of the asset expected to have been located at the specified `index`
     */
    function _afterAcceptAsset(
        uint256 tokenId,
        uint256 index,
        uint256 assetId
    ) internal virtual {}

    /**
     * @notice Hook that is called before rejecting an asset.
     * @param tokenId ID of the token from which the asset is being rejected
     * @param index Index of the asset in the token's pending assets array
     * @param assetId ID of the asset expected to be located at the specified `index`
     */
    function _beforeRejectAsset(
        uint256 tokenId,
        uint256 index,
        uint256 assetId
    ) internal virtual {}

    /**
     * @notice Hook that is called after rejecting an asset.
     * @param tokenId ID of the token from which the asset has been rejected
     * @param index Index of the asset in the token's pending assets array
     * @param assetId ID of the asset expected to have been located at the specified `index`
     */
    function _afterRejectAsset(
        uint256 tokenId,
        uint256 index,
        uint256 assetId
    ) internal virtual {}

    /**
     * @notice Hook that is called before rejecting all assets of a token.
     * @param tokenId ID of the token from which all of the assets are being rejected
     */
    function _beforeRejectAllAssets(uint256 tokenId) internal virtual {}

    /**
     * @notice Hook that is called after rejecting all assets of a token.
     * @param tokenId ID of the token from which all of the assets have been rejected
     */
    function _afterRejectAllAssets(uint256 tokenId) internal virtual {}

    /**
     * @notice Hook that is called before the priorities for token's assets is set.
     * @param tokenId ID of the token for which the asset priorities are being set
     * @param priorities[] An array of priorities for token's active resources
     */
    function _beforeSetPriority(
        uint256 tokenId,
        uint16[] calldata priorities
    ) internal virtual {}

    /**
     * @notice Hook that is called after the priorities for token's assets is set.
     * @param tokenId ID of the token for which the asset priorities have been set
     * @param priorities[] An array of priorities for token's active resources
     */
    function _afterSetPriority(
        uint256 tokenId,
        uint16[] calldata priorities
    ) internal virtual {}

    // --------------------- NESTABLE HOOKS ---------------------

    /**
     * @notice Hook that is called before any token transfer. This includes minting and burning.
     * @dev Calling conditions:
     *
     *  - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be transferred to `to`.
     *  - When `from` is zero, `tokenId` will be minted to `to`.
     *  - When `to` is zero, ``from``'s `tokenId` will be burned.
     *  - `from` and `to` are never zero at the same time.
     *
     *  To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param from Address from which the token is being transferred
     * @param to Address to which the token is being transferred
     * @param tokenId ID of the token being transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @notice Hook that is called after any transfer of tokens. This includes minting and burning.
     * @dev Calling conditions:
     *
     *  - When `from` and `to` are both non-zero.
     *  - `from` and `to` are never zero at the same time.
     *
     *  To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param from Address from which the token has been transferred
     * @param to Address to which the token has been transferred
     * @param tokenId ID of the token that has been transferred
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @notice Hook that is called before nested token transfer.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param from Address from which the token is being transferred
     * @param to Address to which the token is being transferred
     * @param fromTokenId ID of the token from which the given token is being transferred
     * @param toTokenId ID of the token to which the given token is being transferred
     * @param tokenId ID of the token being transferred
     */
    function _beforeNestedTokenTransfer(
        address from,
        address to,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @notice Hook that is called after nested token transfer.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param from Address from which the token was transferred
     * @param to Address to which the token was transferred
     * @param fromTokenId ID of the token from which the given token was transferred
     * @param toTokenId ID of the token to which the given token was transferred
     * @param tokenId ID of the token that was transferred
     */
    function _afterNestedTokenTransfer(
        address from,
        address to,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @notice Hook that is called before a child is added to the pending tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that will receive a new pending child token
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     */
    function _beforeAddChild(
        uint256 tokenId,
        address childAddress,
        uint256 childId
    ) internal virtual {}

    /**
     * @notice Hook that is called after a child is added to the pending tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that has received a new pending child token
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     */
    function _afterAddChild(
        uint256 tokenId,
        address childAddress,
        uint256 childId
    ) internal virtual {}

    /**
     * @notice Hook that is called before a child is accepted to the active tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param parentId ID of the token that will accept a pending child token
     * @param childIndex Index of the child token to accept in the given parent token's pending children array
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     */
    function _beforeAcceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) internal virtual {}

    /**
     * @notice Hook that is called after a child is accepted to the active tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param parentId ID of the token that has accepted a pending child token
     * @param childIndex Index of the child token that was accpeted in the given parent token's pending children array
     * @param childAddress Address of the collection smart contract of the child token that was expected to be located
     *  at the specified index of the given parent token's pending children array
     * @param childId ID of the child token that was expected to be located at the specified index of the given parent
     *  token's pending children array
     */
    function _afterAcceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) internal virtual {}

    /**
     * @notice Hook that is called before a child is transferred from a given child token array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that will transfer a child token
     * @param childIndex Index of the child token that will be transferred from the given parent token's children array
     * @param childAddress Address of the collection smart contract of the child token that is expected to be located
     *  at the specified index of the given parent token's children array
     * @param childId ID of the child token that is expected to be located at the specified index of the given parent
     *  token's children array
     * @param isPending A boolean value signifying whether the child token is being transferred from the pending child
     *  tokens array (`true`) or from the active child tokens array (`false`)
     */
    function _beforeTransferChild(
        uint256 tokenId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending
    ) internal virtual {}

    /**
     * @notice Hook that is called after a child is transferred from a given child token array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that has transferred a child token
     * @param childIndex Index of the child token that was transferred from the given parent token's children array
     * @param childAddress Address of the collection smart contract of the child token that was expected to be located
     *  at the specified index of the given parent token's children array
     * @param childId ID of the child token that was expected to be located at the specified index of the given parent
     *  token's children array
     * @param isPending A boolean value signifying whether the child token was transferred from the pending child tokens
     *  array (`true`) or from the active child tokens array (`false`)
     */
    function _afterTransferChild(
        uint256 tokenId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending
    ) internal virtual {}

    /**
     * @notice Hook that is called before a pending child tokens array of a given token is cleared.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that will reject all of the pending child tokens
     */
    function _beforeRejectAllChildren(uint256 tokenId) internal virtual {}

    /**
     * @notice Hook that is called after a pending child tokens array of a given token is cleared.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that has rejected all of the pending child tokens
     */
    function _afterRejectAllChildren(uint256 tokenId) internal virtual {}

    // --------------------- EQUIPPABLE HOOKS ---------------------

    /**
     * @notice A hook to be called before a equipping a asset to the token.
     * @dev The `IntakeEquip` struct consist of the following data:
     *  [
     *      tokenId,
     *      childIndex,
     *      assetId,
     *      slotPartId,
     *      childAssetId
     *  ]
     * @param data The `IntakeEquip` struct containing data of the asset that is being equipped
     */
    function _beforeEquip(IntakeEquip memory data) internal virtual {}

    /**
     * @notice A hook to be called after equipping a asset to the token.
     * @dev The `IntakeEquip` struct consist of the following data:
     *  [
     *      tokenId,
     *      childIndex,
     *      assetId,
     *      slotPartId,
     *      childAssetId
     *  ]
     * @param data The `IntakeEquip` struct containing data of the asset that was equipped
     */
    function _afterEquip(IntakeEquip memory data) internal virtual {}

    /**
     * @notice A hook to be called before unequipping a asset from the token.
     * @param tokenId ID of the token from which the asset is being unequipped
     * @param assetId ID of the asset being unequipped
     * @param slotPartId ID of the slot from which the asset is being unequipped
     */
    function _beforeUnequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) internal virtual {}

    /**
     * @notice A hook to be called after unequipping a asset from the token.
     * @param tokenId ID of the token from which the asset was unequipped
     * @param assetId ID of the asset that was unequipped
     * @param slotPartId ID of the slot from which the asset was unequipped
     */
    function _afterUnequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) internal virtual {}
}
