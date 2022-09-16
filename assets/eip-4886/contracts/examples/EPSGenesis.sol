// SPDX-License-Identifier: CC0-1.0
// EPSProxy Contracts v1.8.0 (epsproxy/contracts/examples/EPSGenesis.sol)

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@epsproxy/contracts/Proxiable.sol";

/** 
* @dev Contract instance for the EPS Genesis ERC-1155. This contract provides two token
* types designed to showcase the capabilities of the Eternal Proxy Service.
* - Open mint: Every proxy address can mint ONE of these tokens. Delivery will be to the 
*   delivery address. This demonstrates:
*     (a) Retrieval of information and processing based on information in the EPS Register.
*     (b) Delivery of new assets to the delivery address specified on the register.
* - Gated mint: Every proxy address that acts for a nominator one of three pre-determined  
*   NFTs can mint the 'gated' token. This will again be delivered to the delivery address 
*   specified on the EPS register. In addition this demonstrates:
*     (c) Checking of the contract balance of the Nominator to determine eligibility. In
*         this use of the EPS register risk to the eligibility asset is entirely eliminated
*         as the contract interaction is with the proxy address, which does not hold the 
*         asset, not the nominator.
*/ 
contract EPSGenesis is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply, Proxiable {

/** 
* @dev Not required, but provided to give consistency with ERC-721 in terms of display
* in tools like etherscan:
*/     
  string public constant NAME = "EPSGenesis";
  string public constant SYMBOL = "EPSGEN"; 

  /** 
  * @dev Definition of token classes and max supply of each:
  */     
  uint256 public constant OPEN_TOKEN = 0;
  uint256 public constant GATED_TOKEN = 1;
  uint256 public constant MAX_SUPPLY_OPEN = 10000;
  uint256 public constant MAX_SUPPLY_GATED = 10000;

  /** 
  * @dev tokens that need to be held to mint the gated tokens, provided on the constructor:
  */ 
  address public immutable GATE_1;
  address public immutable GATE_2;
  address public immutable GATE_3;

  /** 
  * @dev each address is entitled to just ONE of each type. Each is free, except gas.
  */ 
  mapping (address => bool) minterHasMintedOpen;
  mapping (address => bool) minterHasMintedGated;

  constructor(address _epsRegisterAddress, address _GATE_1, address _GATE_2, address _GATE_3, string memory _contractURI) 
    ERC1155(_contractURI) 
    Proxiable(_epsRegisterAddress) {
    GATE_1 = _GATE_1;
    GATE_2 = _GATE_2;
    GATE_3 = _GATE_3;
  }

  /** 
  * @dev modifiers to control access based on previous minting:
  */ 
  modifier hasNotAlreadyMintedOpen(address _receivedAddress) {
    require(minterHasMintedOpen[_receivedAddress] != true, "Address has already minted in open mint, allocation exhausted");
    _;
  }

  modifier hasNotAlreadyMintedGated(address _receivedAddress) {
    require(minterHasMintedGated[_receivedAddress] != true, "Address has already minted in gated mint, allocation exhausted");
    _;
  }

  /** 
  * @dev modifier to only allow minting from a proxy address:
  */ 
  modifier isProxyAddress(address _receivedAddress) {
    require(proxyRecordExists(_receivedAddress), "Only a proxy address can mint this token - go to app.epsproxy.com");
    _;
  }

  /** 
  * @dev modifier to ensure supply(s) is not exhausted:
  */ 
  modifier supplyNotExhaustedOpen() {
    require(totalSupply(OPEN_TOKEN) < MAX_SUPPLY_OPEN, "Max supply reached for open mint - cannot be minted");
    _;
  }

  modifier supplyNotExhaustedGated() {
    require(totalSupply(GATED_TOKEN) < MAX_SUPPLY_GATED, "Max supply reached for gated mint - cannot be minted");
    _;
  }

  /** 
  * @dev perform minting of the open tokens:
  */ 
  function proxyMintOpen(address _receivedAddress) internal hasNotAlreadyMintedOpen(_receivedAddress) isProxyAddress(_receivedAddress) supplyNotExhaustedOpen() {
    address nominator;
    address delivery;
    bool isProxied;
    (nominator, delivery, isProxied) = getAddresses(_receivedAddress);

    _mint(delivery, OPEN_TOKEN, 1, "");

    minterHasMintedOpen[_receivedAddress] = true; 
  }

  /** 
  * @dev perform minting of the gated tokens:
  */ 
  function proxyMintGated(address _receivedAddress) internal hasNotAlreadyMintedGated(_receivedAddress) isProxyAddress(_receivedAddress) supplyNotExhaustedGated() {
    address nominator;
    address delivery;
    bool isProxied;
    (nominator, delivery, isProxied) = getAddresses(_receivedAddress);

    require((IERC721(GATE_1).balanceOf(nominator) >= 1 || IERC721(GATE_2).balanceOf(nominator) >= 1 || IERC721(GATE_3).balanceOf(nominator) >= 1), "Must hold an eligible token for this mint");

    _mint(delivery, GATED_TOKEN, 1, "");
    
    minterHasMintedGated[_receivedAddress] = true; 
  }

  /** 
  * @dev external function for minting calls. Required boolean values for open and gated minting (can pass both as true to perform both)
  */ 
  function mintEPSGenesis(bool mintOpen, bool mintGated) external {
    if (mintOpen) {
      proxyMintOpen(msg.sender);
    }
    if (mintGated) {
      proxyMintGated(msg.sender);
    }
  }

  /** 
  * @dev external and public functions to determine eligibility off-chain:
  */ 
  function hasMintedOpen(address _receivedAddress) external view returns (bool) {
    return(minterHasMintedOpen[_receivedAddress]);
  }

  function hasMintedGated(address _receivedAddress) external view returns (bool) {
    return(minterHasMintedGated[_receivedAddress]);
  }

  function hasAProxyRecord(address _receivedAddress) external view returns (bool) {
    return(proxyRecordExists(_receivedAddress));
  }

  function hasNominatorWithEligibleToken(address _receivedAddress) public view returns (bool) {
    address nominator;
    address delivery;
    bool isProxied;
    (nominator, delivery, isProxied) = getAddresses(_receivedAddress);
    return((IERC721(GATE_1).balanceOf(nominator) >= 1 || IERC721(GATE_2).balanceOf(nominator) >= 1 || IERC721(GATE_3).balanceOf(nominator) >= 1));
  }

  function addressStatus(address _receivedAddress) public view returns (bool open, bool gated, bool proxy, bool eligible) {
    return(minterHasMintedOpen[_receivedAddress], minterHasMintedGated[_receivedAddress], proxyRecordExists(_receivedAddress), hasNominatorWithEligibleToken(_receivedAddress));
  }

  /** 
  * @dev name, max and total supply for tools like etherscan:
  */ 
  function name() public pure returns (string memory) {
    return NAME;
  }

  function symbol() public pure returns (string memory) {
    return SYMBOL;
  }

  function totalSupply() public pure returns (uint256) {
    return (MAX_SUPPLY_OPEN + MAX_SUPPLY_GATED);
  }

  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
      internal
      override(ERC1155, ERC1155Supply)
  {
      super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
}