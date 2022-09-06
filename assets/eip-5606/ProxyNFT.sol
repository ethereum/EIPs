// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract ERC721Full is ERC721Enumerable, ERC721URIStorage {
    /// @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
    /// @param name is a non-empty string
    /// @param symbol is a non-empty string
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    /// @dev Hook that is called before any token transfer. This includes minting and burning. `from`'s `tokenId` will be transferred to `to`
    /// @param from is an non-zero address
    /// @param to is an non-zero address
    /// @param tokenId is an uint256 which determine token transferred from `from` to `to`
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Interface of the ERC165 standard
    /// @param interfaceId is a byte4 which determine interface used
    /// @return true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC721Enumerable.supportsInterface(interfaceId);
    }

    /// @notice the Uniform Resource Identifier (URI) for `tokenId` token
    /// @param tokenId is unit256
    /// @return string of (URI) for `tokenId` token
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721URIStorage, ERC721)
        returns (string memory)
    {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {}
}

/**
 * @dev Interface of the Proxy NFT standard as defined in the EIP.
 */
interface IProxyNFT {

    /**
     * @dev struct to store delegate token details
     *
     */
    struct DelegateData {
        address contractAddress;
        uint256 tokenId;
        uint256 quantity;
        bool isBundled;
        address ownerAddress;
    }

    /**
     * @dev Emitted when one or more new delegate NFTs are added to a Proxy NFT 
     *
     */
    event Bundled(uint256 proxyTokenID, DelegateData[] delegateData, address ownerAddress);

    /**
     * @dev Emitted when one or more delegate NFTs are removed from a Proxy NFT 
     */
    event Unbundled(uint256 proxyTokenID, DelegateData[] delegateData);

    /**
     * @dev Accepts the tokenId of the Proxy NFT and returns an array of delegate token data
     */
    function delegateTokens(uint256 proxyTokenID) external view returns (DelegateData[] memory);

    /**
     * @dev Removes one or more delegate NFTs from a Proxy NFT
     * This function accepts the delegate NFT details, and transfer those NFTs out of the Proxy NFT contract to the owner's wallet
     */
    function unBundle(DelegateData[] memory delegateData, uint256 proxyTokenID) external;

    /**
     * @dev Adds one or more delegate NFTs to a Proxy NFT
     * This function accepts the delegate NFT details, and transfers those NFTs to the Proxy NFT contract
     * Need to ensure that approval is given to this Proxy NFT contract for the delegate NFTs so that they can be transferred programmatically
     */
    function bundle(DelegateData[] memory delegateData, uint256 proxyTokenID, address ownerAddress) external;

    /**
     * @dev Initializes a new bundle, mints a Proxy NFT and assigns it to msg.sender
     * Returns the token ID of a new Proxy NFT
     * Note - When a new Proxy NFT is initialized, it is empty, it does not contain any delegate NFTs
     */
    function initBundle(DelegateData[] memory delegateData) external;
}

abstract contract ProxyNFT is 
    IProxyNFT,
    Ownable,
    ERC721Full,
    IERC1155Receiver,
    AccessControl
{
    using SafeMath for uint256;
    bytes32 public constant BUNDLER_ROLE = keccak256("BUNDLER_ROLE");

    uint256 currentProxyTokenID;

    struct RemainingQuantity {
        uint256 proxyTokenID;
        address contractAddress;

    }
    
    mapping(uint256 => DelegateData[]) public proxyNFTDelegateData;
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public tokenBalances;

    constructor(
        address bundlerAddress
    ){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BUNDLER_ROLE, msg.sender);
        _setRoleAdmin(BUNDLER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(BUNDLER_ROLE, bundlerAddress);
    }

    function delegateTokens(uint256 proxyTokenID) external view returns (DelegateData[] memory){
        return proxyNFTDelegateData[proxyTokenID];
    }

    function initBundle(DelegateData[] memory delegateData) external {
        uint256 tokenId = currentProxyTokenID.add(1);
        for(uint256 i = 0; i <delegateData.length; i = i.add(1)){
            bool isERC721 = _isERC721(delegateData[i].contractAddress);
            if(isERC721){
                require(delegateData[i].quantity == 1, "ERC721 quantity must be 1");
            }
            proxyNFTDelegateData[tokenId].push(delegateData[i]);
        }

        _incrementProxyTokenID();
        _safeMint(msg.sender, tokenId);
    }

    function bundle(DelegateData[] memory delegateData, uint256 proxyTokenID, address ownerAddress) external {
        require(hasRole(BUNDLER_ROLE, msg.sender) || ownerOf(proxyTokenID) == msg.sender ,"msg.sender neither have bundler role nor proxytoken owner");
        require(ownerOf(proxyTokenID) == ownerAddress, "ownerAddress is not an owner of proxytoken");
        _bundle(delegateData,proxyTokenID,ownerAddress);
    }

    function unBundle(DelegateData[] memory delegateData, uint256 proxyTokenID) external{
        require(ownerOf(proxyTokenID) == msg.sender,"msg.sender is not a proxytoken owner");
        for(uint256 i = 0; i < delegateData.length; i = i.add(1)){
            require(_ensureDelegateBelongsToProxyNFT(delegateData[i], proxyTokenID), "delegate not assigned to proxy token");
            uint256 balance = tokenBalances[proxyTokenID][delegateData[i].contractAddress][delegateData[i].tokenId];
            require(delegateData[i].quantity <= balance, "quantity exceeds balance");
            require(_ensureDelegateCanUnbundled(delegateData[i], proxyTokenID), "delegate cannot be unbundled");
            require(_ensureProxyContractOwnsDelegate(delegateData[i]), "delegate not owned by contract");           
            
            address contractAddress = delegateData[i].contractAddress;
            uint256 tokenId =  delegateData[i].tokenId;
            uint256 quantity = delegateData[i].quantity;

            uint256 remainingBalance = _updateDelegateBalances(delegateData[i], proxyTokenID);
            if(remainingBalance == 0){
                _updateDelegateStatusToUnbundled(delegateData[i], proxyTokenID);
            }
        
           if(_isERC721(contractAddress)){
                ERC721Full erc721Instance = ERC721Full(contractAddress);
                erc721Instance.transferFrom(address(this), msg.sender, tokenId);
            }
            else if(_isERC1155(contractAddress)){
                ERC1155Supply erc1155Instance = ERC1155Supply(contractAddress);
                erc1155Instance.safeTransferFrom(address(this), msg.sender, tokenId, quantity, "");
            }
            else{
                revert("unable to identify ERC std");
            }
        }
        emit Unbundled(proxyTokenID, delegateData);
    }

    function supportsInterface(bytes4 interfaceId)
            public
            view
            override(AccessControl, ERC721Full, IERC165)
            returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC721Full.supportsInterface(interfaceId);
    }


    function _bundle(DelegateData[] memory delegateData, uint256 proxyTokenID, address ownerAddress) internal {
        for(uint256 i = 0; i < delegateData.length; i = i.add(1)){
            require(_ensureDelegateBelongsToProxyNFT(delegateData[i], proxyTokenID), "delegate not assigned to proxytoken");
            require(_ensureDelegateQuantityLimitForMProxyNFT(delegateData[i], proxyTokenID), "delegate quantity assigned to proxytoken exceeds");

            address contractAddress = delegateData[i].contractAddress;
            uint256 tokenId =  delegateData[i].tokenId;
            uint256 quantity = delegateData[i].quantity;

            tokenBalances[proxyTokenID][contractAddress][tokenId] = tokenBalances[proxyTokenID][contractAddress][tokenId].add(quantity);

            _updateDelegateStatusAndOwner(delegateData[i],ownerAddress,true, proxyTokenID);
            
            if(_isERC721(contractAddress)){
                require(quantity == 1, "ERC721 cannot have quantity more than 1");
                ERC721Full erc721Instance = ERC721Full(contractAddress);
                erc721Instance.transferFrom(msg.sender, address(this), tokenId);
            }
            else if(_isERC1155(contractAddress)){
                ERC1155Supply erc1155Instance = ERC1155Supply(contractAddress);
                erc1155Instance.safeTransferFrom(msg.sender, address(this), tokenId, quantity, "");
            }
            else{
                revert("unable to identify ERC std");
            }
        }
        emit Bundled(proxyTokenID,delegateData,ownerAddress);
    }

   function _ensureDelegateBelongsToProxyNFT(DelegateData memory delegateData, uint256 proxyTokenID) internal view returns(bool){
        DelegateData[] memory storedData = proxyNFTDelegateData[proxyTokenID];
        for(uint256 i = 0; i <storedData.length; i = i.add(1)){
            if(delegateData.contractAddress == storedData[i].contractAddress && delegateData.tokenId == storedData[i].tokenId){
                return true;
            }
        }
        return false;
    }

    function _ensureProxyContractOwnsDelegate(DelegateData memory delegateData) internal view returns(bool){   
        if(_isERC721(delegateData.contractAddress)){
            ERC721Full erc721Instance = ERC721Full(delegateData.contractAddress);
            if(address(this) == erc721Instance.ownerOf(delegateData.tokenId)){
                return true;
            }
        }
        else if(_isERC1155(delegateData.contractAddress)){
            ERC1155Supply erc1155Instance = ERC1155Supply(delegateData.contractAddress);
            if(erc1155Instance.balanceOf(address(this), delegateData.tokenId) >= delegateData.quantity){
                return true;
            }
        }
        return false;
    }

    function _ensureDelegateCanUnbundled(DelegateData memory delegateData, uint256 proxyTokenID) internal view returns(bool){
        DelegateData[] memory storedData = proxyNFTDelegateData[proxyTokenID];
        for(uint256 i = 0; i <storedData.length; i = i.add(1)){
            if(delegateData.contractAddress == storedData[i].contractAddress && delegateData.tokenId == storedData[i].tokenId && storedData[i].isBundled && msg.sender == storedData[i].ownerAddress){
                return true;
            }
        }
        return false;
    }

    function _ensureDelegateQuantityLimitForMProxyNFT(DelegateData memory delegateData, uint256 proxyTokenID) internal view returns(bool){
        DelegateData[] memory storedData = proxyNFTDelegateData[proxyTokenID];
        for(uint256 i = 0; i <storedData.length; i = i.add(1)){
            if(delegateData.contractAddress == storedData[i].contractAddress && delegateData.tokenId == storedData[i].tokenId){
                uint256 balance = tokenBalances[proxyTokenID][delegateData.contractAddress][delegateData.tokenId];
                if(balance.add(delegateData.quantity) <= storedData[i].quantity){
                    return true;
                }
                return false;
            }
        }

        return false;
    }

    function _updateDelegateStatusAndOwner(DelegateData memory delegateData, address ownerAddress, bool status, uint256 proxyTokenID) internal returns(bool){
        DelegateData[] storage storedData = proxyNFTDelegateData[proxyTokenID];
        for(uint256 i = 0; i <storedData.length; i = i.add(1)){
            if(delegateData.contractAddress == storedData[i].contractAddress && delegateData.tokenId == storedData[i].tokenId){
                storedData[i].isBundled = status;
                storedData[i].ownerAddress = ownerAddress;
                return true;
            }
        }
        return false;
    }

    function _updateDelegateStatusToUnbundled(DelegateData memory delegateData, uint256 proxyTokenID) internal returns(bool){
        DelegateData[] storage storedData = proxyNFTDelegateData[proxyTokenID];
        for(uint256 i = 0; i <storedData.length; i = i.add(1)){
            if(delegateData.contractAddress == storedData[i].contractAddress && delegateData.tokenId == storedData[i].tokenId){
                storedData[i].isBundled = false;
                return true;
            }
        }
        return false;
    }

    function _updateDelegateBalances(DelegateData memory delegateData, uint256 proxyTokenID) internal returns(uint256){
        address contractAddress = delegateData.contractAddress;
        uint256 tokenId = delegateData.tokenId;
        tokenBalances[proxyTokenID][contractAddress][tokenId] = tokenBalances[proxyTokenID][contractAddress][tokenId].sub(delegateData.quantity);
        return tokenBalances[proxyTokenID][contractAddress][tokenId];
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Full) {
        DelegateData[] storage storedData = proxyNFTDelegateData[tokenId];
        for(uint256 i = 0; i <storedData.length; i = i.add(1)){
            storedData[i].ownerAddress = to;
        }
        ERC721Full._beforeTokenTransfer(from,to,tokenId);
    }

    function _isERC1155(address contractAddress) internal view returns (bool){
        return IERC1155(contractAddress).supportsInterface(0xd9b67a26);
    }   

    function _isERC721(address contractAddress) internal view returns (bool){
        return IERC721(contractAddress).supportsInterface(0x80ac58cd);
    }

    function _incrementProxyTokenID() internal {
        currentProxyTokenID = currentProxyTokenID.add(1);
    }

}
