// SPDX-License-Identifier: CC0-1.0
// EPSProxy Contracts v1.7.0 (epsproxy/contracts/EPS.sol)

pragma solidity ^0.8.9;

/**
 * @dev Implementation of the EPS register interface.
 */
interface EPS {
  // Emitted when an address nominates a proxy address:
  event NominationMade(address indexed nominator, address indexed proxy, uint256 timestamp, uint256 provider);
  // Emitted when an address accepts a proxy nomination:
  event NominationAccepted(address indexed nominator, address indexed proxy, address indexed delivery, uint256 timestamp, uint256 provider);
  // Emitted when the proxy address updates the delivery address on a record:
  event DeliveryUpdated(address indexed nominator, address indexed proxy, address indexed delivery, address oldDelivery, uint256 timestamp, uint256 provider);
  // Emitted when a nomination record is deleted. initiator 0 = nominator, 1 = proxy:
  event NominationDeleted(string initiator, address indexed nominator, address indexed proxy, uint256 timestamp, uint256 provider);
  // Emitted when a register record is deleted. initiator 0 = nominator, 1 = proxy:
  event RecordDeleted(string initiator, address indexed nominator, address indexed proxy, address indexed delivery, uint256 timestamp, uint256 provider);
  // Emitted when the register fee is set:
  event RegisterFeeSet(uint256 indexed registerFee);
  // Emitted when the treasury address is set:
  event TreasuryAddressSet(address indexed treasuryAddress);
  // Emitted on withdrawal to the treasury address:
  event Withdrawal(uint256 indexed amount, uint256 timestamp);

  function nominationExists(address _nominator) external view returns (bool);
  function nominationExistsForCaller() external view returns (bool);
  function proxyRecordExists(address _proxy) external view returns (bool);
  function proxyRecordExistsForCaller() external view returns (bool);
  function nominatorRecordExists(address _nominator) external view returns (bool);
  function nominatorRecordExistsForCaller() external view returns (bool);
  function getProxyRecord(address _proxy) external view returns (address nominator, address proxy, address delivery);
  function getProxyRecordForCaller() external view returns (address nominator, address proxy, address delivery);
  function getNominatorRecord(address _nominator) external view returns (address nominator, address proxy, address delivery);
  function getNominatorRecordForCaller() external view returns (address nominator, address proxy, address delivery);
  function addressIsActive(address _receivedAddress) external view returns (bool);
  function addressIsActiveForCaller() external view returns (bool);
  function getNomination(address _nominator) external view returns (address proxy);
  function getNominationForCaller() external view returns (address proxy);
  function getAddresses(address _receivedAddress) external view returns (address nominator, address delivery, bool isProxied);
  function getAddressesForCaller() external view returns (address nominator, address delivery, bool isProxied);
  function getRole(address _roleAddress) external view returns (string memory currentRole);
  function getRoleForCaller() external view returns (string memory currentRole);
  function makeNomination(address _proxy, uint256 _provider) external payable;
  function acceptNomination(address _nominator, address _delivery, uint256 _provider) external;
  function updateDeliveryAddress(address _delivery, uint256 _provider) external;
  function deleteRecordByNominator(uint256 _provider) external;
  function deleteRecordByProxy(uint256 _provider) external;
  function setRegisterFee(uint256 _registerFee) external returns (bool);
  function getRegisterFee() external view returns (uint256 _registerFee);
  function setTreasuryAddress(address _treasuryAddress) external returns (bool);
  function getTreasuryAddress() external view returns (address _treasuryAddress);
  function withdraw(uint256 _amount) external returns (bool);
}