// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import 'contracts/interface/IFund.sol';
import 'contracts/periphery/roles/AgentRoleFund.sol';
import "contracts/periphery/storage/FundStorage.sol";
import "contracts/interface/IToken.sol";
import "contracts/interface/IAPIConsumer.sol";
import "contracts/periphery/APIConsumer.sol";
import "contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "contracts/interface/ITokenFactory.sol";


contract Fund is Initializable, IFund, AgentRoleFund, FundStorage {

    function init(address _token, string calldata _fundName, address fmAddress, 
                uint8 _assetType, 
                string calldata _issuerName, 
                uint256 _targetAUM,
                uint128 _NAVLaunchPrice, string calldata _NAVEndPoint) external initializer{
        _transferOwnership(msg.sender);
        addAgent(msg.sender);
        factory = address(msg.sender);

        fundName = _fundName;
        token = _token;
        fundManagerAddress = fmAddress;
        assetType = _assetType;
        issuerName = _issuerName;
        targetAUM = _targetAUM;
        NAVLaunchPrice = _NAVLaunchPrice;
        issueDate = block.timestamp;

        address _apiConsumer = address(new APIConsumer(_NAVEndPoint));
        setConsumer(_apiConsumer);
    }

    function addUserManagementFee(address[] calldata _address, uint256[] calldata _fee) public onlyAgent{
        require(_address.length == _fee.length, "Invalid Input");
        for(uint8 i =0; i < _address.length; i++){
            managementFee[_address[i]] = _fee[i];
        }
    }

    // function setStableCoin(address _stableCoin) public onlyAgent{
    //     stableCoin = _stableCoin;
    // }

    function _addUserDividend(address _address, uint256 _dividend, uint8 _key) internal{
            if(_key == 0){
                dividend[_address].Token = _dividend;
            }
            else if(_key == 1){
                dividend[_address].StableCoin = _dividend;
            }
            else {
                dividend[_address].Fiat = _dividend;
            }
    }

    function setConsumer(address _Consumer) public onlyAgent{
        apiConsumer =_Consumer;
    }
    function getNAV() external returns (uint256){
        IAPIConsumer api = IAPIConsumer(apiConsumer);
        NAVLatestPrice = api.getPrice();
        return NAVLatestPrice;
    }

    function getAUM() external returns (uint256){
        IToken mytoken = IToken(token);
        uint256 circulatingSupply = mytoken.circulationSupply();
        AssetUnderManagement = circulatingSupply * NAVLatestPrice;
        return AssetUnderManagement;
    }

    function getManagementFee(address _userAddress) external view returns(uint256){
        return managementFee[_userAddress];
    }

    function updateFundManager(address _newFundManager) public onlyAgent{
        require(_newFundManager != address(0), "Zero Address not Allowed");
        fundManagerAddress = _newFundManager;
    }

    function updateTerm(uint256 _newTerm) public onlyAgent{
        require(_newTerm > 0,"Invalid Term");
        termOfFund = _newTerm;
    }

    function updateFundCurrency(string calldata _newCurrency) public onlyAgent{
        fundCurrency = _newCurrency;
    }

    function updateDividendCycle(uint256 _newCycle) public onlyAgent{
        require(_newCycle > 0, "Invalid input");
        dividendCycle = _newCycle;
    }

    function updateIRR(uint _newIRR) public onlyAgent{
        iRR = _newIRR;
    }

    function updateManagementFees(address _userAddress, uint256 _updatedFees) public onlyAgent{
        require(_userAddress != address(0), "Invalid Address");
        managementFee[_userAddress] = _updatedFees;
    }

    function updateNAVEndPoint(string calldata _newEndPoint) public onlyAgent{
        IAPIConsumer api = IAPIConsumer(apiConsumer);
        api.updateEndpoint(_newEndPoint);
    }

    function getStableCoin(uint8 coin) external view returns(address stableCoin){
        ITokenFactory fcty = ITokenFactory(factory);
        stableCoin = fcty.getStableCoin(coin);
    }

    function shareDividend(address[] calldata _address, uint256[] calldata _dividend, address _from, uint8[] calldata _key, uint8 coin) public onlyAgent{
        require(_address.length == _dividend.length && _dividend.length == _key.length, "Invalid Input");
        
        ITokenFactory fcty = ITokenFactory(factory);
        stableCoin = fcty.getStableCoin(coin);
        for(uint i=0; i<_address.length; i++){
        if(_key[i] == 0 ){
            IToken(token).mint(_address[i], _dividend[i]);
        }
        else if(_key[i] == 1){
            TransferHelper.safeTransferFrom(stableCoin, _from, _address[i], _dividend[i]);
        }
        _addUserDividend(_address[i], _dividend[i], _key[i]);
        }
    }

    function distributeAndBurn(address[] calldata _investors, uint256[] calldata _amount, uint256[] calldata _tokens, address _from, uint8 coin) public onlyAgent{
        require(_investors.length == _amount.length && _amount.length == _tokens.length, "Invalid Input");

        IToken tkn = IToken(token);
        ITokenFactory fcty = ITokenFactory(factory);
        stableCoin = fcty.getStableCoin(coin);

        for(uint i = 0; i < _investors.length; i++){

            tkn.burn(_investors[i], _tokens[i]);

            TransferHelper.safeTransferFrom(stableCoin, _from, _investors[i], _amount[i]);
        }
    }

    function rescueAnyERC20Tokens(
        address _tokenAddr,
        address _to,
        uint128 _amount
    ) external onlyAgent {
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(_tokenAddr),
            _to,
            _amount
        );
    }
}