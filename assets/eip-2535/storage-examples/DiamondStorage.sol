// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Diamond storage is a contract storage strategy that is used in proxy contracts and diamonds.

// It greatly simplifies organizing and using state variables in proxy contracts and diamonds.

// Diamond storage relies on Solidity structs that contain sets of state variables.

// A struct can be defined with state variables and then used in a particular position in contract 
// storage. The position can be determined by a hash of a unique string or other data. The string 
// acts like a namespace for the struct. For example a diamond storage string for a struct could 
// be 'com.mycompany.projectx.mystruct'. That will look familiar to you if you have used programming 
// languages  that use namespaces.

// Namespaces are used in some programming languages to package data and code together as separate 
// reusable units. Diamond storage packages sets of state variables as separate, reusable data units 
// in contract storage.

// Let's look at a simple example of diamond storage:

library LibERC721 {
    bytes32 constant ERC721_POSITION = keccak256("erc721.storage");

    // Instead of using a hash of a string other schemes can be used to create positions in contract storage.
    // Here is a scheme that could be used:
    // 
    // bytes32 constant ERC721_POSITION = 
    //    keccak256(abi.encodePacked(
    //        ERC721.interfaceId, 
    //        ERC721.name
    //    ));

    struct ERC721Storage {
        // tokenId => owner
        mapping (uint256 => address) tokenIdToOwner;
        // owner => count of tokens owned
        mapping (address => uint256) ownerToNFTokenCount;
        
        string name;
        string symbol;   
    }

    // Return ERC721 storage struct for reading and writing
    function getStorage() internal pure returns (ERC721Storage storage storageStruct) {
        bytes32 position = ERC721_POSITION;
        assembly {
            storageStruct.slot := position
        }
    }

     event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    // This is a very simplified implementation. 
    // It does not include all necessary validation of input. 
    // It is used to show diamond storage.
    function transferFrom(address _from, address _to, uint256 _tokenId) internal {
        ERC721Storage storage erc721Storage = LibERC721.getStorage();
        address tokenOwner = erc721Storage.tokenIdToOwner[_tokenId];
        require(tokenOwner == _from);
        erc721Storage.tokenIdToOwner[_tokenId] = _to;
        erc721Storage.ownerToNFTokenCount[_from]--;
        erc721Storage.ownerToNFTokenCount[_to]++;
        emit Transfer(_from, _to, _tokenId);
    }
}

// Note that this is not a full or correct ERC721 implementation.
// This is an example of using diamond storage.

// Note that the ERC721.name and ERC721.symbol storage variables would probably be set
// in an `init` function at deployment time or during an upgrade.


// Shows use of LibERC721 and diamond storage
contract ERC721Facet {
    
    function name() external view returns (string memory name_) {
        name_ = LibERC721.getStorage().name;
    }
    
    function symbol() external view returns (string memory symbol_) {
        symbol_ = LibERC721.getStorage().symbol;
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        LibERC721.transferFrom(_from, _to, _tokenId);
    }

}

// Here we show how we can share state variables and internal functions between facets by
// using Solidity libraries. Sharing internal functions between facets can also be done by 
// inheriting contracts that contain internal functions.
contract ERC721BatchTransferFacet {

    function batchTransferFrom(address _from, address _to, uint256[] calldata _tokenIds) external {
        for(uint256 i; i < _tokenIds.length; i++) {
          LibERC721.transferFrom(_from, _to, _tokenIds[i]);
        }
    }
}

// HOW TO UPGRADE DIAMOND STORAGE
//--------------------------------------------

// It is important not to corrupt state variables during an upgrade. It is easy to handle state
// variables correctly in upgrades.

// Here's some things that can be done:

// 1. To add new state variables to an AppStorage struct or a Diamond Storage struct, add them 
//    to the end of the struct.

// 2. New state variables can be added to the ends of structs that are stored in mappings.

// 3. The names of state variables can be changed, but that might be confusing if different 
//    facets are using different names for the same storage locations.

// Do not do the following:

// 1. If you are using AppStorage then do not declare and use state variables outside the 
//    AppStorage struct. Except Diamond Storage can be used. Diamond Storage and AppStorage
//    can be used together.

// 2. Do not add new state variables to the beginning or middle of structs. Doing this 
//    makes the new state variable overwrite existing state variable data and all state 
//    variables after the new state variable reference the wrong storage location.

// 3. Do not put structs directly in structs unless you don’t plan on ever adding more state 
//    variables to the inner structs. You won't be able to add new state variables to inner 
//    structs in upgrades.

// 4. Do not add new state variables to structs that are used in arrays.

// 5. When using Diamond Storage do not use the same namespace string for different structs. 
//    This is obvious. Two different structs at the same location will overwrite each other.

// 6. Do not allow any facet to be able to call `selfdestruct`. This is easy. Simply don’t 
//    allow the `selfdestruct` command to exist in any facet source code and don’t allow 
//    that command to be called via a delegatecall. Because `selfdestruct` could delete a 
//    facet that is used by a diamond, or `selfdestruct` could be used to delete a diamond 
//    proxy contract.

// A trick to use inner structs and still enable them to be extended is to put them in mappings. 
// A struct stored in a mapping can be extended in upgrades. You could use a value like 0 defined 
// with a constant like INNER_STRUCT. Put your structs in mappings and then access them with the 
// INNER_STRUCT constant. Example: MyStruct storage mystruct = storage.mystruct[INNER_STRUCT];

// Note that any Solidity data type can be used in Diamond Storage or AppStorage structs. It is 
// just that structs directly in structs and structs that are used in arrays can’t be extended 
// with more state variables in the future. That could be fine in some cases.

// These rules will make sense if you understand how Solidity assigns storage locations to state 
// variables. I recommend reading and understanding this section of the Solidity documentation: 
// 'Layout of State Variables in Storage'
