// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/RightsManagement.sol";

contract ContractTest is Test {

  event CreateLicense(
      uint256 licenseId,
      uint256 tokenId,
      uint256 parentLicenseId,
      address licenseHolder,
      string uri,
      address revoker
      );
  event RevokeLicense(uint256 licenseId);
  event TransferLicense(uint256 licenseId, address licenseHolder);

  //Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
  RightsManagement rm;

  address add1 = address(0xadd1);
  address add2 = address(0xadd2);
  address add3 = address(0xadd3);
  string tokenURI = "tokenURI";
  string licenseURI = "licenseURI";
  string sublicenseURI = "sublicenseURI";

  function setUp() public {
    vm.deal(add1, 12 ether);
    vm.deal(add2, 12 ether);
    vm.deal(add3, 12 ether);

    rm = new RightsManagement("MyNFT", "NFT");
  }

  function testMint() public {
    vm.expectEmit(true,true,true,true); // put this two lines before you actually call the function
    emit CreateLicense(1, 1, 0, add1, licenseURI, add3); // the expected log you expect to see emitted
    uint tokenId = rm.safeMint(add1, tokenURI, licenseURI, add3);
    address tokenOwner = rm.ownerOf(tokenId);
    assertEq(add1, tokenOwner, "tokenOwner should match");
    uint256 licenseId = rm.getLicenseIdByTokenId(tokenId);
    assertEq(rm.isLicenseActive(0), false, "License 0 should be inactive");
    assertEq(rm.isLicenseActive(licenseId), true, "License should be active");
    assertEq(rm.getLicenseURI(licenseId), licenseURI, "License should match");
    assertEq(rm.getLicenseHolder(licenseId), add1, "LicenseHolder should match");
    assertEq(rm.getLicenseTokenId(licenseId), 1, "TokenId should match");
    assertEq(rm.getParentLicenseId(licenseId), 0, "Parent License Id should match");
    assertEq(rm.getLicenseRevoker(licenseId), add3, "License revoker should match");
  }

  function testCreateLicense() public {
    uint tokenId = rm.safeMint(add1, tokenURI, licenseURI, add3);
    uint parentLicenseId = rm.getLicenseIdByTokenId(tokenId);

    vm.startPrank(add1);
    vm.expectEmit(true,true,true,true); // put this two lines before you actually call the function
    emit CreateLicense(2, 1, 1, add2, sublicenseURI, add3); // the expected log you expect to see emitted
    uint licenseId = rm.createLicense(tokenId, parentLicenseId, add2, sublicenseURI, add3);
    vm.stopPrank();

    vm.expectRevert("Sender is not eligible to grant a new license");
    licenseId = rm.createLicense(tokenId, parentLicenseId, add2, sublicenseURI, add3);
  }

  function testRevokeLicense() public {
    uint tokenId = rm.safeMint(add1, tokenURI, licenseURI, add3);
    uint parentLicenseId = rm.getLicenseIdByTokenId(tokenId);

    vm.startPrank(add1);
    uint licenseId = rm.createLicense(tokenId, parentLicenseId, add2, sublicenseURI, add3);
    vm.stopPrank();

    vm.startPrank(add2);
    licenseId = rm.createLicense(tokenId, licenseId, add3, sublicenseURI, add3);
    vm.stopPrank();

    vm.startPrank(add3);
    vm.expectEmit(true,true,true,true); // put this two lines before you actually call the function
    emit RevokeLicense(2); // the expected log you expect to see emitted
    rm.revokeLicense(2);
    vm.stopPrank();

    vm.startPrank(add3);
    vm.expectRevert("The license is not active");
    rm.revokeLicense(3);
    vm.stopPrank();


    vm.startPrank(add1);
    vm.expectRevert("The msg sender is not an eligible revoker");
    rm.revokeLicense(1);
    vm.stopPrank();

    vm.startPrank(add3);
    rm.revokeLicense(1);
    vm.stopPrank();
    assertEq(rm.ownerOf(1), address(this), "The token should be returned to creator after revoking its license");

    assertEq(rm.getLicenseIdByTokenId(1), 0, "The token should not have an active license");
  }

  function testTransfer() public {
    uint tokenId = rm.safeMint(add1, tokenURI, licenseURI, add3);

    vm.startPrank(add3);
    rm.revokeLicense(1);
    vm.stopPrank();

    vm.expectRevert("The token has no active license tethered to it");
    rm.safeTransferFrom(address(this), add1, 1);

    vm.expectEmit(true,true,true,true); // put this two lines before you actually call the function
    emit CreateLicense(2, 1, 0, address(this), licenseURI, add3); // the expected log you expect to see emitted
    rm.createLicense(tokenId, 0, address(this), licenseURI, add3);

    vm.expectEmit(true,true,true,true); // put this two lines before you actually call the function
    emit TransferLicense(2, add2); // the expected log you expect to see emitted
    rm.safeTransferFrom(address(this), add2, 1);
    assertEq(rm.getLicenseIdByTokenId(1), 2, "License Id linked to tokenId");
    assertEq(rm.getLicenseHolder(2), add2, "License holder updated");
  }

  function testIssue() public {
    uint tokenId = rm.safeMint(add1, tokenURI, licenseURI, add3);

    vm.startPrank(add3);
    rm.revokeLicense(1);
    vm.stopPrank();

    vm.expectEmit(true,true,true,true); // put this two lines before you actually call the function
    emit CreateLicense(2, 1, 0, address(this), licenseURI, add3); // the expected log you expect to see emitted
    emit TransferLicense(2, add2); // the expected log you expect to see emitted
    rm.safeIssue(add2, tokenId, licenseURI, add3);
    assertEq(rm.getLicenseIdByTokenId(1), 2, "License Id linked to tokenId");
    assertEq(rm.getLicenseHolder(2), add2, "License holder updated");
  }
  
  function testTransferSublicense() public {
    uint tokenId = rm.safeMint(add1, tokenURI, licenseURI, add3);

    vm.startPrank(add3);
    rm.revokeLicense(1);
    vm.stopPrank();

    vm.expectRevert("The license is not active");
    rm.transferSublicense(1, add2);

    vm.expectEmit(true,true,true,true); // put this two lines before you actually call the function
    emit CreateLicense(2, 1, 0, add1, licenseURI, add3); // the expected log you expect to see emitted
    rm.createLicense(tokenId, 0, add1, licenseURI, add3);

    vm.expectRevert("The license is a root license");
    rm.transferSublicense(2, add2);
    
    vm.startPrank(add1);
    rm.createLicense(tokenId, 2, add2, licenseURI, add3);
    vm.stopPrank();

    vm.expectRevert("The msg sender is not the license holder");
    rm.transferSublicense(3, add1);
    
    vm.startPrank(add2);
    vm.expectEmit(true,true,true,true); // put this two lines before you actually call the function
    emit TransferLicense(3, add1); // the expected log you expect to see emitted
    rm.transferSublicense(3, add1);
    vm.stopPrank();
  }
}
