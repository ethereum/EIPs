// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.7.6;

import './MetaProxyFactory.sol';

/// @notice This contract includes test cases for the MetaProxy standard.
contract MetaProxyTest is MetaProxyFactory {
  uint256 public someValue;

  event SomeEvent(
    address a,
    uint256 b,
    uint256[] c
  );
  event SomeData(bytes data);

  /// @notice One-time initializer.
  function init () external payable {
    require(someValue == 0);

    (, uint256 b, ) = MetaProxyTest(this).getMetadataViaCall();
    require(b > 0);
    someValue = b;
  }

  /// @notice MetaProxy construction via abi encoded bytes.
  /// Arguments are reversed for testing purposes.
  function createFromBytes (
    uint256[] calldata c,
    uint256 b,
    address a
  ) external payable returns (address proxy) {
    // creates a new proxy where the metadata is the result of abi.encode()
    proxy = MetaProxyFactory._metaProxyFromBytes(address(this), abi.encode(a, b, c));
    require(proxy != address(0));
    // optional one-time setup, a constructor() substitute
    MetaProxyTest(proxy).init{ value: msg.value }();
  }

  /// @notice MetaProxy construction via calldata.
  function createFromCalldata (
    address a,
    uint256 b,
    uint256[] calldata c
  ) external payable returns (address proxy) {
    // creates a new proxy where the metadata is everything after the 4th byte from calldata.
    proxy = MetaProxyFactory._metaProxyFromCalldata(address(this));
    require(proxy != address(0));
    // optional one-time setup, a constructor() substitute
    MetaProxyTest(proxy).init{ value: msg.value }();
  }

  /// @notice Returns the metadata of this (MetaProxy) contract.
  /// Only relevant with contracts created via the MetaProxy standard.
  /// @dev This function is aimed to be invoked with- & without a call.
  function getMetadataWithoutCall () public pure returns (
    address a,
    uint256 b,
    uint256[] memory c
  ) {
    bytes memory data;
    assembly {
      let posOfMetadataSize := sub(calldatasize(), 32)
      let size := calldataload(posOfMetadataSize)
      let dataPtr := sub(posOfMetadataSize, size)
      data := mload(64)
      // increment free memory pointer by metadata size + 32 bytes (length)
      mstore(64, add(data, add(size, 32)))
      mstore(data, size)
      let memPtr := add(data, 32)
      calldatacopy(memPtr, dataPtr, size)
    }
    return abi.decode(data, (address, uint256, uint256[]));
  }

  /// @notice Returns the metadata of this (MetaProxy) contract.
  /// Only relevant with contracts created via the MetaProxy standard.
  /// @dev This function is aimed to to be invoked via a call.
  function getMetadataViaCall () public pure returns (
    address a,
    uint256 b,
    uint256[] memory c
  ) {
    assembly {
      let posOfMetadataSize := sub(calldatasize(), 32)
      let size := calldataload(posOfMetadataSize)
      let dataPtr := sub(posOfMetadataSize, size)
      calldatacopy(0, dataPtr, size)
      return(0, size)
    }
  }

  /// @notice Runs all test cases
  function testAll () external payable {
    (address a, uint256 b, uint256[] memory c) = abc();
    MetaProxyTest self = MetaProxyTest(address(this));

    {
      address proxy = self.createFromCalldata(a, b, c);
      testProxy(proxy);
    }
    {
      address proxy = self.createFromBytes(c, b, a);
      testProxy(proxy);
    }
  }

  function abc () public returns (address a, uint256 b, uint256[] memory c) {
    a = address(this);
    b = 0xc0ffe;
    c = new uint256[](9);
  }

  function testProxy (address _proxy) public {
    require(_proxy != address(0));

    (address a, uint256 b, uint256[] memory c) = abc();
    MetaProxyTest proxy = MetaProxyTest(_proxy);

    {
      (address x, uint256 y, uint256[] memory z) = proxy.getMetadataViaCall();
      require(a == x && b == y && keccak256(abi.encode(c)) == keccak256(abi.encode(z)));
    }
    {
      (address x, uint256 y, uint256[] memory z) = proxy.getMetadataWithoutCall();
      require(a == x && b == y && keccak256(abi.encode(c)) == keccak256(abi.encode(z)));
    }

    require(proxy.someValue() == b);
    require(proxy.testReturnSingle() == b);

    bytes memory _bytes = hex'68656c6c6f20776f726c64';
    (uint256 x, uint256[] memory y) = proxy.testReturnMulti(_bytes, uint160(address(this)) + b);
    require(x == b);
    require(y.length == c.length);

    (bool success, bytes memory returnData) = _proxy.call(abi.encodeWithSignature('testRevert(string)', _bytes));
    require(success == false);
    require(keccak256(returnData) == keccak256(abi.encodeWithSignature('Error(string)', _bytes)));
  }

  function testReturnSingle () public returns (uint256) {
    (
      address a,
      uint256 b,
      uint256[] memory c
    ) = MetaProxyTest(this).getMetadataViaCall();

    require(a == msg.sender);
    require(b == someValue);
    require(c.length == 9);

    emit SomeEvent(a, b, c);

    return b;
  }

  function testReturnMulti (bytes memory data, uint256 xyz) public returns (uint256, uint256[] memory) {
    (
      address a,
      uint256 b,
      uint256[] memory c
    ) = getMetadataWithoutCall();

    require(a == msg.sender);
    require(b == someValue);
    require(c.length == 9);
    require(xyz == uint160(a) + b);

    bytes memory expected = hex'68656c6c6f20776f726c64';
    require(data.length == expected.length);
    for (uint256 i = 0; i < expected.length; i++) {
      require(data[i] == expected[i]);
    }

    emit SomeEvent(a, b, c);
    emit SomeData(data);

    return (b, c);
  }

  function testRevert (string memory data) public {
    (address a,,) = getMetadataWithoutCall();

    // should evaluate to `true`
    if (a != address(0)) {
      revert(data);
    }
  }
}
