// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IFund {

    function init(address _token, string calldata _fundName, address fmAddress, 
                uint8 _assetType, 
                string calldata _issuerName, 
                uint256 _targetAUM,
                uint128 _NAVLaunchPrice, string calldata _NAVEndPoint) external;

    function addUserManagementFee(address[] calldata _address, uint256[] calldata _fee) external;

    function _addUserDividend(address _address, uint256 _dividend, uint8 _key) external;

    function setConsumer(address _Consumer) external;

    function managementFee(address _userAddress) external returns(uint256);

    function getAUM() external returns (uint256);

    function getNAV() external returns (uint256);

    function updateFundManager(address _newFundManager) external;

    function updateTerm(uint256 _newTerm) external;

    function updateFundCurrency(string calldata _newCurrency) external;

    function updateDividendCycle(uint256 _newCycle) external;

    function updateIRR(uint _newIRR) external;

    function updateManagementFees(address _userAddress, uint256 _updatedFees) external;

    function updateNAVEndPoint(string calldata _newEndPoint) external;

    function getStableCoin(uint8 coin) external view returns(address stableCoin);

    function shareDividend(address[] calldata _address, uint256[] calldata _dividend, address _from, uint8[] calldata _key, uint8 coin) external;

    function distributeAndBurn(address[] calldata _investors, uint256[] calldata _amount, uint256[] calldata _tokens, address _from, uint8 coin) external;

    function rescueAnyERC20Tokens(address _tokenAddr, address _to, uint128 _amount) external;
}