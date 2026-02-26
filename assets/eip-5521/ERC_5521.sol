// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC_5521.sol";

contract ERC_5521 is ERC721, IERC_5521, TargetContract {

    struct Relationship {
        mapping (address => uint256[]) referring;
        mapping (address => uint256[]) referred;
        uint256 createdTimestamp; // unix timestamp when the rNFT is being created
    }

    mapping (uint256 => Relationship) internal _relationship;
    address contractOwner = address(0);

    mapping (uint256 => address[]) private referringKeys;
    mapping (uint256 => address[]) private referredKeys;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        contractOwner = msg.sender;
    }

    function safeMint(uint256 tokenId, address[] memory addresses, uint256[][] memory _tokenIds) public {
        // require(msg.sender == contractOwner, "ERC_rNFT: Only contract owner can mint");
        _safeMint(msg.sender, tokenId);
        setNode(tokenId, addresses, _tokenIds);
    }

    /// @notice set the referred list of an rNFT associated with different contract addresses and update the referring list of each one in the referred list
    /// @param tokenIds array of rNFTs, recommended to check duplication at the caller's end
    function setNode(uint256 tokenId, address[] memory addresses, uint256[][] memory tokenIds) public virtual override {
        require(
            addresses.length == tokenIds.length,
            "Addresses and TokenID arrays must have the same length"
        );
        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i].length == 0) { revert("ERC_5521: the referring list cannot be empty"); }
        }
        setNodeReferring(addresses, tokenId, tokenIds);
        setNodeReferred(addresses, tokenId, tokenIds);
    }

    /// @notice set the referring list of an rNFT associated with different contract addresses 
    /// @param _tokenIds array of rNFTs associated with addresses, recommended to check duplication at the caller's end
    function setNodeReferring(address[] memory addresses, uint256 tokenId, uint256[][] memory _tokenIds) private {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC_5521: transfer caller is not owner nor approved");

        Relationship storage relationship = _relationship[tokenId];

        for (uint i = 0; i < addresses.length; i++) {
            if (relationship.referring[addresses[i]].length == 0) { referringKeys[tokenId].push(addresses[i]); } // Add the address if it's a new entry
            relationship.referring[addresses[i]] = _tokenIds[i];
        }

        relationship.createdTimestamp = block.timestamp;
        emitEvents(tokenId, msg.sender);
    }

    /// @notice set the referred list of an rNFT associated with different contract addresses 
    /// @param _tokenIds array of rNFTs associated with addresses, recommended to check duplication at the caller's end
    function setNodeReferred(address[] memory addresses, uint256 tokenId, uint256[][] memory _tokenIds) private {
        for (uint i = 0; i < addresses.length; i++) {
            if (addresses[i] == address(this)) {
                for (uint j = 0; j < _tokenIds[i].length; j++) {
                    if (_relationship[_tokenIds[i][j]].referred[addresses[i]].length == 0) { referredKeys[_tokenIds[i][j]].push(addresses[i]); } // Add the address if it's a new entry
                    Relationship storage relationship = _relationship[_tokenIds[i][j]];

                    require(tokenId != _tokenIds[i][j], "ERC_5521: self-reference not allowed");
                    if (relationship.createdTimestamp >= block.timestamp) { revert("ERC_5521: the referred rNFT needs to be a predecessor"); } // Make sure the reference complies with the timing sequence

                    relationship.referred[address(this)].push(tokenId);
                    emitEvents(_tokenIds[i][j], ownerOf(_tokenIds[i][j]));
                }
            } else {
                TargetContract targetContractInstance = TargetContract(addresses[i]);
                targetContractInstance.setNodeReferredExternal(address(this), tokenId, _tokenIds[i]);
            }
        }
    }

    /// @notice set the referred list of an rNFT associated with different contract addresses 
    /// @param _tokenIds array of rNFTs associated with addresses, recommended to check duplication at the caller's end
    function setNodeReferredExternal(address _address, uint256 tokenId, uint256[] memory _tokenIds) external {
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (_relationship[_tokenIds[i]].referred[_address].length == 0) { referredKeys[_tokenIds[i]].push(_address); } // Add the address if it's a new entry
            Relationship storage relationship = _relationship[_tokenIds[i]];

            require(_address != address(this), "ERC_5521: this must be an external contract address");
            if (relationship.createdTimestamp >= block.timestamp) { revert("ERC_5521: the referred rNFT needs to be a predecessor"); } // Make sure the reference complies with the timing sequence

            relationship.referred[_address].push(tokenId);
            emitEvents(_tokenIds[i], ownerOf(_tokenIds[i]));
        }
    }

    /// @notice Get the referring list of an rNFT
    /// @param tokenId The considered rNFT, _address The corresponding contract address
    /// @return The referring mapping of an rNFT
    function referringOf(address _address, uint256 tokenId) external view virtual override(IERC_5521, TargetContract) returns (address[] memory, uint256[][] memory) {
        address[] memory _referringKeys;
        uint256[][] memory _referringValues;

        if (_address == address(this)) {
            require(_exists(tokenId), "ERC_5521: token ID not existed");
            (_referringKeys, _referringValues) = convertMap(tokenId, true);
        } else {
            TargetContract targetContractInstance = TargetContract(_address);
            (_referringKeys, _referringValues) = targetContractInstance.referringOf(_address, tokenId);           
        }      
        return (_referringKeys, _referringValues);
    }

    /// @notice Get the referred list of an rNFT
    /// @param tokenId The considered rNFT, _address The corresponding contract address
    /// @return The referred mapping of an rNFT
    function referredOf(address _address, uint256 tokenId) external view virtual override(IERC_5521, TargetContract) returns (address[] memory, uint256[][] memory) {
        address[] memory _referredKeys;
        uint256[][] memory _referredValues;

        if (_address == address(this)) {
            require(_exists(tokenId), "ERC_5521: token ID not existed");
            (_referredKeys, _referredValues) = convertMap(tokenId, false);
        } else {
            TargetContract targetContractInstance = TargetContract(_address);
            (_referredKeys, _referredValues) = targetContractInstance.referredOf(_address, tokenId);           
        }
        return (_referredKeys, _referredValues);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC_5521).interfaceId
            || interfaceId == type(TargetContract).interfaceId
            || super.supportsInterface(interfaceId);    
    }

    // @notice Emit an event of UpdateNode
    function emitEvents(uint256 tokenId, address sender) private {
        (address[] memory _referringKeys, uint256[][] memory _referringValues) = convertMap(tokenId, true);
        (address[] memory _referredKeys, uint256[][] memory _referredValues) = convertMap(tokenId, false);
        
        emit UpdateNode(tokenId, sender, _referringKeys, _referringValues, _referredKeys, _referredValues);
    }

    // @notice Convert a specific `local` token mapping to a key array and a value array
    function convertMap(uint256 tokenId, bool isReferring) private view returns (address[] memory, uint256[][] memory) {
        Relationship storage relationship = _relationship[tokenId];

        address[] memory returnKeys;
        uint256[][] memory returnValues;

        if (isReferring) {
            returnKeys = referringKeys[tokenId];
            returnValues = new uint256[][](returnKeys.length);
            for (uint i = 0; i < returnKeys.length; i++) {
                returnValues[i] = relationship.referring[returnKeys[i]];
            }            
        } else {
            returnKeys = referredKeys[tokenId];
            returnValues = new uint256[][](returnKeys.length);
            for (uint i = 0; i < returnKeys.length; i++) {
                returnValues[i] = relationship.referred[returnKeys[i]];
            }
        }
        return (returnKeys, returnValues);
    }
}