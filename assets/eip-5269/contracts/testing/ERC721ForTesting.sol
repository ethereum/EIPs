// SPDX-License-Identifier: CC0-1.0
// Author: Zainan Victor Zhou <ercref@zzn.im>
// DRAFTv1
// Source https://github.com/ercref/ercref-contracts/tree/main/ERCs/eip-5269
// Deployment https://goerli.etherscan.io/address/0x33F735852619E3f99E1AF069cCf3b9232b2806bE#code
pragma solidity ^0.8.9;
// import 721
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// impport 5269
import "../ERC5269.sol";

contract ERC721ForTesting is ERC721, ERC5269 {

    bytes32 constant public EIP_FINAL = keccak256("FINAL");
    constructor() ERC721("ERC721ForTesting", "E721FT") ERC5269() {
        _mint(msg.sender, 0);
        emit OnSupportEIP(address(0x0), 721, bytes32(0), EIP_FINAL, "");
        emit OnSupportEIP(address(0x0), 721, keccak256("ERC721Metadata"), EIP_FINAL, "");
        emit OnSupportEIP(address(0x0), 721, keccak256("ERC721Enumerable"), EIP_FINAL, "");
    }

  function supportEIP(
    address caller,
    uint256 majorEIPIdentifier,
    bytes32 minorEIPIdentifier,
    bytes calldata extraData)
  external
  override
  view
  returns (bytes32 eipStatus) {
    if (majorEIPIdentifier == 721) {
      if (minorEIPIdentifier == 0) {
        return keccak256("FINAL");
      } else if (minorEIPIdentifier == keccak256("ERC721Metadata")) {
        return keccak256("FINAL");
      } else if (minorEIPIdentifier == keccak256("ERC721Enumerable")) {
        return keccak256("FINAL");
      }
    }
    return super._supportEIP(caller, majorEIPIdentifier, minorEIPIdentifier, extraData);
  }
}
