// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC7496} from "src/dynamic-traits/interfaces/IERC7496.sol";
import {ERC721DynamicTraits, DynamicTraits} from "src/dynamic-traits/ERC721DynamicTraits.sol";
import {Solarray} from "solarray/Solarray.sol";

contract ERC721DynamicTraitsTest is Test {
    ERC721DynamicTraits token;

    /* Events */
    event TraitUpdated(bytes32 indexed traitKey, uint256 indexed tokenId, bytes32 value);
    event TraitUpdatedBulkConsecutive(bytes32 indexed traitKeyPattern, uint256 fromTokenId, uint256 toTokenId);
    event TraitUpdatedBulkList(bytes32 indexed traitKeyPattern, uint256[] tokenIds);
    event TraitLabelsURIUpdated(string uri);

    function setUp() public {
        token = new ERC721DynamicTraits();
    }

    function testSupportsInterfaceId() public {
        assertTrue(token.supportsInterface(type(IERC7496).interfaceId));
    }

    function testReturnsValueSet() public {
        bytes32 key = bytes32("test.key");
        bytes32 value = bytes32("foo");
        uint256 tokenId = 12345;

        vm.expectEmit(true, true, true, true);
        emit TraitUpdated(key, tokenId, value);

        token.setTrait(key, tokenId, value);

        assertEq(token.getTraitValue(key, tokenId), value);
    }

    function testOnlyOwnerCanSetValues() public {
        address alice = makeAddr("alice");
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        token.setTrait(bytes32("test"), 0, bytes32("test"));
    }

    function testSetTrait_Unchanged() public {
        bytes32 key = bytes32("test.key");
        bytes32 value1 = bytes32("foo");
        uint256 tokenId1 = 1;

        token.setTrait(key, tokenId1, value1);
        vm.expectRevert(DynamicTraits.TraitValueUnchanged.selector);
        token.setTrait(key, tokenId1, value1);
    }

    function testGetTraitValues() public {
        bytes32 key = bytes32("test.key");
        bytes32 value1 = bytes32("foo");
        bytes32 value2 = bytes32("bar");
        uint256 tokenId1 = 1;
        uint256 tokenId2 = 2;

        token.setTrait(key, tokenId1, value1);
        token.setTrait(key, tokenId2, value2);

        bytes32[] memory values = token.getTraitValues(key, Solarray.uint256s(tokenId1, tokenId2));
        assertEq(values[0], value1);
        assertEq(values[1], value2);
    }

    function testGetTotalTraitKeys() public {
        bytes32 key1 = bytes32("test.key");
        bytes32 key2 = bytes32("test.key2");
        bytes32 value1 = bytes32("foo");
        bytes32 value2 = bytes32("bar");
        uint256 tokenId1 = 1;
        uint256 tokenId2 = 2;

        assertEq(token.getTotalTraitKeys(), 0);

        token.setTrait(key1, tokenId1, value1);
        assertEq(token.getTotalTraitKeys(), 1);

        token.setTrait(key2, tokenId2, value2);
        assertEq(token.getTotalTraitKeys(), 2);
    }

    function testGetTraitKeyAt() public {
        bytes32 key1 = bytes32("test.key");
        bytes32 key2 = bytes32("test.key2");
        bytes32 value1 = bytes32("foo");
        bytes32 value2 = bytes32("bar");
        uint256 tokenId1 = 1;
        uint256 tokenId2 = 2;

        token.setTrait(key1, tokenId1, value1);

        token.setTrait(key2, tokenId2, value2);

        assertEq(token.getTraitKeyAt(0), key1);
        assertEq(token.getTraitKeyAt(1), key2);
    }

    function testGetTraitKeys() public {
        bytes32 key1 = bytes32("test.key");
        bytes32 key2 = bytes32("test.key2");
        bytes32 value1 = bytes32("foo");
        bytes32 value2 = bytes32("bar");
        uint256 tokenId1 = 1;
        uint256 tokenId2 = 2;

        token.setTrait(key1, tokenId1, value1);
        token.setTrait(key2, tokenId2, value2);

        bytes32[] memory traitKeys = token.getTraitKeys();
        assertEq(traitKeys[0], key1);
        assertEq(traitKeys[1], key2);
    }

    function testGetAndSetTraitLabelsURI() public {
        string memory uri = "https://example.com/labels.json";
        token.setTraitLabelsURI(uri);
        assertEq(token.getTraitLabelsURI(), uri);

        vm.prank(address(0x1234));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(0x1234)));
        token.setTraitLabelsURI(uri);
    }

    function testGetTraitValue_TraitNotSet() public {
        bytes32 key = bytes32("test.key");
        uint256 tokenId = 1;

        vm.expectRevert(abi.encodeWithSelector(DynamicTraits.TraitNotSet.selector, tokenId, key));
        token.getTraitValue(key, tokenId);
    }

    function testGetTraitValue_ZeroValue() public {
        bytes32 key = bytes32("test.key");
        uint256 tokenId = 1;

        token.setTrait(key, tokenId, bytes32(0));
        bytes32 result = token.getTraitValue(key, tokenId);
        assertEq(result, bytes32(0), "should return bytes32(0)");
    }

    function testGetTraitValues_ZeroValue() public {
        bytes32 key = bytes32("test.key");
        uint256 tokenId = 1;

        token.setTrait(key, tokenId, bytes32(0));
        bytes32[] memory result = token.getTraitValues(key, Solarray.uint256s(tokenId));
        assertEq(result[0], bytes32(0), "should return bytes32(0)");
    }

    function testSetTrait_ZeroValueHash() public {
        bytes32 key = bytes32("test.key");
        uint256 tokenId = 1;
        bytes32 badValue = keccak256("DYNAMIC_TRAITS_ZERO_VALUE");

        vm.expectRevert(abi.encodeWithSelector(IERC7496.InvalidTraitValue.selector, key, badValue));
        token.setTrait(key, tokenId, badValue);
    }

    function testdeleteTrait() public {}
}