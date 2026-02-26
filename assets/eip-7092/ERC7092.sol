// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC7092.sol";
import "./BondStorage.sol";

/**
* @notice Minimum implementation of the ERC7092
*/
contract ERC7092 is IERC7092, BondStorage {
    constructor(
        string memory _bondISIN,
        Issuer memory _issuerInfo
    )  {
        bondISIN = _bondISIN;
        _bondManager = msg.sender;
        _issuer[_bondISIN] = _issuerInfo;
    }

    function issue(
        IssueData[] memory _issueData,
        Bond memory _bond
    ) external onlyBondManager {
        _issue(_issueData, _bond);
    }

    function redeem() external onlyBondManager {
        _redeem(_listOfInvestors);
    }

    function _issue(IssueData[] memory _issueData, Bond memory _bondInfo) internal virtual {
        uint256 volume;
        uint256 _issueVolume = _bondInfo.issueVolume;
      
        for(uint256 i; i < _issueData.length; i++) {
            address investor = _issueData[i].investor;
            uint256 principal = _issueData[i].principal;
            uint256 _denomination = _bondInfo.denomination;
            
            require(investor != address(0), "ERC7092: ZERO_ADDRESS_INVESTOR");
            require(principal != 0 && (principal * _denomination) % _denomination == 0, "ERC: INVALID_PRINCIPAL_AMOUNT");

            volume += principal;
            _principals[investor] = principal;
            _listOfInvestors.push(IssueData({investor:investor, principal:principal}));
        }
        
        _bond[bondISIN] = _bondInfo;
        _bond[bondISIN].issueDate = block.timestamp;
        _bondStatus = BondStatus.ISSUED;

        uint256 _maturityDate = _bond[bondISIN].maturityDate;

        require(_maturityDate > block.timestamp, "ERC7092: INVALID_MATURITY_DATE");
        require(volume == _issueVolume, "ERC7092: INVALID_ISSUE_VOLUME");

        emit BondIssued(_issueData, _bondInfo);
    }

    function _redeem(IssueData[] memory _bondsData) internal virtual {
        uint256 _maturityDate = _bond[bondISIN].maturityDate;
        require(block.timestamp > _maturityDate, "ERC2721: WAIT_MATURITY");

        for(uint256 i; i < _bondsData.length; i++) {
            if(_principals[_bondsData[i].investor] != 0) {
                _principals[_bondsData[i].investor] = 0;
            }
        }

        _bondStatus = BondStatus.REDEEMED;
        emit BondRedeemed();
    }

    function isin() external view returns(string memory) {
        return _bond[bondISIN].isin;
    }

    function name() external view returns(string memory) {
        return _bond[bondISIN].name;
    }

    function symbol() external view returns(string memory) {
        return _bond[bondISIN].symbol;
    }

    function decimals() external view returns(uint8) {
        return _bond[bondISIN].decimals;
    }

    function currency() external view returns(address) {
        return _bond[bondISIN].currency;
    }

    function currencyOfCoupon() external view returns(address) {
        return _bond[bondISIN].currencyOfCoupon;
    }

    function denomination() public view returns(uint256) {
        return _bond[bondISIN].denomination;
    }

    function issueVolume() external view returns(uint256) {
        return _bond[bondISIN].issueVolume;
    }

    function couponRate() external view returns(uint256) {
        return _bond[bondISIN].couponRate;
    }

    function couponType() external view returns(uint256) {
        return _bond[bondISIN].couponType;
    }

    function couponFrequency() external view returns(uint256) {
        return _bond[bondISIN].couponFrequency;
    }

    function issueDate() external view returns(uint256) {
        return _bond[bondISIN].issueDate;
    }

    function maturityDate() public view returns(uint256) {
        return _bond[bondISIN].maturityDate;
    }

    function dayCountBasis() external view returns(uint256) {
        return _bond[bondISIN].dayCountBasis;
    }

    function principalOf(address _account) external view returns(uint256) {
        return _principals[_account];
    }

    function balanceOf(address _account) public view returns(uint256) {
        require(_bondStatus == BondStatus.ISSUED, "ERC7092: NOT_ISSUED_OR_REDEEMED");

        return _principals[_account] / _bond[bondISIN].denomination;
    }

    function totalSupply() public view returns(uint256) {
        require(_bondStatus == BondStatus.ISSUED, "ERC7092: NOT_ISSUED_OR_REDEEMED");

        return _bond[bondISIN].issueVolume / _bond[bondISIN].denomination;
    }

    function approval(address _owner, address _spender) external view returns(uint256) {
        return _approvals[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external returns(bool) {
        address _owner = msg.sender;

        _approve(_owner, _spender, _amount);

        return true;
    }

    function approveAll(address _spender) external external returns(bool) {
        address _owner = msg.sender;
        uint256 _amount = _principals[_owner];

        _approve(_owner, _spender, _amount);

        return true;
    }

    function decreaseAllowance(address _spender, uint256 _amount) external returns(bool) {
        address _owner = msg.sender;

        _decreaseAllowance(_owner, _spender, _amount);

        return true;
    }

    function decreaseAllowanceForAll(address _spender) external returns(bool) {
        address _owner = msg.sender;
        uint256 _amount = _principals[_owner];

        _decreaseAllowance(_owner, _spender, _amount);

        return true;
    }

    function transfer(address _to, uint256 _amount, bytes calldata _data) external returns(bool) {
        address _from = msg.sender;

        _transfer(_from, _to, _amount, _data);

        return true;
    }

    function transferAll(address _to, bytes calldata _data) external returns(bool) {
        address _from = msg.sender;
        uint256 _amount = _principals[_from];

        _transfer(_from, _to, _amount, _data);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount, bytes calldata _data) external returns(bool) {
        address _spender = msg.sender;

        _spendApproval(_from, _spender, _amount);

        _transfer(_from, _to, _amount, _data);

        return true;
    }

    function transferAllFrom(address _from, address _to, bytes calldata _data) external returns(bool) {
        address _spender = msg.sender;
        uint256 _amount = _principals[_from];

        _spendApproval(_from, _spender, _amount);

        _transfer(_from, _to, _amount, _data);

        return true;
    }

    function _approve(address _owner, address _spender, uint256 _amount) internal virtual {
        require(_owner != address(0), "ERC7092: OWNER_ZERO_ADDRESS");
        require(_spender != address(0), "ERC7092: SPENDER_ZERO_ADDRESS");
        require(_amount > 0, "ERC7092: INVALID_AMOUNT");

        uint256 principal = _principals[_owner];
        uint256 _approval = _approvals[_owner][_spender];
        uint256 _denomination = denomination();
        uint256 _maturityDate = maturityDate();

        require(block.timestamp < _maturityDate, "ERC7092: BONDS_MATURED");
        require(_amount <= principal, "ERC7092: INSUFFICIENT_BALANCE");
        require(_amount % _denomination == 0, "ERC7092: INVALID_AMOUNT");

        _approvals[_owner][_spender]  = _approval + _amount;

        emit Approved(_owner, _spender, _amount);
    }

    function _decreaseAllowance(address _owner, address _spender, uint256 _amount) internal virtual {
        require(_owner != address(0), "ERC7092: OWNER_ZERO_ADDRESS");
        require(_spender != address(0), "ERC7092: SPENDER_ZERO_ADDRESS");
        require(_amount > 0, "ERC7092: INVALID_AMOUNT");

        uint256 _approval = _approvals[_owner][_spender];
        uint256 _denomination = denomination();
        uint256 _maturityDate = maturityDate();

        require(block.timestamp < _maturityDate, "ERC7092: BONDS_MATURED");
        require(_amount <= _approval, "ERC7092: NOT_ENOUGH_APPROVAL");
        require(_amount % _denomination == 0, "ERC7092: INVALID_AMOUNT");

        _approvals[_owner][_spender]  = _approval - _amount;

        emit AllowanceDecreased(_owner, _spender, _amount);
    }

    function _transfer(address _from, address _to, uint256 _amount, bytes calldata _data) internal virtual {
        require(_from != address(0), "ERC7092: OWNER_ZERO_ADDRESS");
        require(_to != address(0), "ERC7092: SPENDER_ZERO_ADDRESS");
        require(_amount > 0, "ERC7092: INVALID_AMOUNT");

        uint256 principal = _principals[_from];
        uint256 _denomination = denomination();
        uint256 _maturityDate = maturityDate();

        require(block.timestamp < _maturityDate, "ERC7092: BONDS_MATURED");
        require(_amount <= principal, "ERC7092: INSUFFICIENT_BALANCE");
        require(_amount % _denomination == 0, "ERC7092: INVALID_AMOUNT");

        _beforeBondTransfer(_from, _to, _amount, _data);

        uint256 principalTo = _principals[_to];

        unchecked {
            _principals[_from] = principal - _amount;
            _principals[_to] = principalTo + _amount;
        }

        emit Transferred(_from, _to, _amount, _data);

        _afterBondTransfer(_from, _to, _amount, _data);
    }

   function  _spendApproval(address _from, address _spender, uint256 _amount) internal virtual {
        uint256 currentApproval = _approvals[_from][_spender];
        require(_amount <= currentApproval, "ERC7092: INSUFFICIENT_ALLOWANCE");

        unchecked {
            _approvals[_from][_spender] = currentApproval - _amount;
        }
   }

    function _beforeBondTransfer(address _from, address _to, uint256 _amount, bytes calldata _data) internal virtual {}

    function _afterBondTransfer(address _from, address _to, uint256 _amount, bytes calldata _data) internal virtual {}
}
