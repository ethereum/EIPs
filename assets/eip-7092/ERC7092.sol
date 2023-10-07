// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC7092.sol";
import "./BondStorage.sol";

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

    function isin() external view returns(string memory) {
        return _bonds[bondISIN].isin;
    }

    /**
    * @notice Returns the bond name
    */
    function name() external view returns(string memory) {
        return _bonds[bondISIN].name;
    }

    /**
    * @notice Returns the bond symbol
    *         It is RECOMMENDED to represent the symbol as a combination of the issuer Issuer'shorter name and the maturity date
    *         Ex: If a company named Green Energy issues bonds that will mature on october 25, 2030, the bond symbol could be `GE30` or `GE2030` or `GE102530`
    */
    function symbol() external view returns(string memory) {
        return _bonds[bondISIN].symbol;
    }

    /**
    * @notice Returns the bond currency. This is the contract address of the token used to pay and return the bond principal
    */
    function currency() external view returns(address) {
        return _bonds[bondISIN].currency;
    }

    /**
    * @notice Returns the bond denominiation. This is the minimum amount in which the Bonds may be issued. It must be expressend in unit of the principal currency
    *         ex: If the denomination is equal to 1,000 and the currency is USDC, then the bond denomination is equal to 1,000 USDC
    */
    function denomination() external view returns(uint256) {
        return _bonds[bondISIN].denomination;
    }

    /**
    * @notice Returns the issue volume (total debt amount). It is RECOMMENDED to express the issue volume in denomination unit.
    */
    function issueVolume() external view returns(uint256) {
        return _bonds[bondISIN].issueVolume;
    }

    /**
    * @notice Returns the bond tokens total supply
    */
    function totalSupply() external view returns(uint256) {
        return _bonds[bondISIN].issueVolume / _bonds[bondISIN].denomination;
    }

    /**
    * @notice Returns the bond interest rate. It is RECOMMENDED to express the interest rate in basis point unit.
    *         1 basis point = 0.01% = 0.0001
    *         ex: if interest rate = 5%, then coupon() => 500 basis points
    */
    function couponRate() external view returns(uint256) {
        return _bonds[bondISIN].couponRate;
    }

    /**
    * @notice Returns the date when bonds were issued to investors. This is a Unix Timestamp like the one returned by block.timestamp
    */
    function issueDate() external view returns(uint256) {
        return _bonds[bondISIN].issueDate;
    }

    /**
    * @notice Returns the bond maturity date, i.e, the date when the pricipal is repaid. This is a Unix Timestamp like the one returned by block.timestamp
    *         The maturity date MUST be greater than the issue date
    */
    function maturityDate() external view returns(uint256) {
        return _bonds[bondISIN].maturityDate;
    }

    /**
    * @notice Returns the principal of an account. It is RECOMMENDED to express the principal in the bond currency unit (USDC, DAI, etc...)
    * @param _account account address
    */
    function principalOf(address _account) external view returns(uint256) {
        return _principals[_account];
    }

    /**
    * @notice Returns the balance of an account
    * @param _account account address
    */
    function balanceOf(address _account) external view returns(uint256) {
        return _principals[_account] / _bonds[bondISIN].denomination;
    }

    /**
    * @notice Returns the amount of tokens the `_spender` account has been authorized by the `_owner``
    *         acount to manage their bonds
    * @param _owner the bondholder address
    * @param _spender the address that has been authorized by the bondholder
    */
    function allowance(address _owner, address _spender) external view returns(uint256) {
        return _allowed[_owner][_spender];
    }

    /**
    * @notice Authorizes `_spender` account to manage `_amount`of their bond tokens
    * @param _spender the address to be authorized by the bondholder
    * @param _amount amount of bond tokens to approve
    */
    function approve(address _spender, uint256 _amount) external returns(bool) {
        address _owner = msg.sender;

        _approve(_owner, _spender, _amount);

        return true;
    }

    /**
    * @notice Lowers the allowance of `_spender` by `_amount`
    * @param _spender the address to be authorized by the bondholder
    * @param _amount amount of bond tokens to remove from allowance
    */
    function decreaseAllowance(address _spender, uint256 _amount) external returns(bool) {
        address _owner = msg.sender;

        _decreaseAllowance(_owner, _spender, _amount);

        return true;
    }

    /**
    * @notice Moves `_amount` bonds to address `_to`. This methods also allows to attach data to the token that is being transferred
    * @param _to the address to send the bonds to
    * @param _amount amount of bond tokens to transfer
    * @param _data additional information provided by the token holder
    */
    function transfer(address _to, uint256 _amount, bytes calldata _data) external returns(bool) {
        address _from = msg.sender;

        _transfer(_from, _to, _amount, _data);

        return true;
    }

    /**
    * @notice Moves `_amount` bonds from an account that has authorized the caller through the approve function
    *         This methods also allows to attach data to the token that is being transferred
    * @param _from the bondholder address
    * @param _to the address to transfer bonds to
    * @param _amount amount of bond tokens to transfer.
    * @param _data additional information provided by the token holder
    */
    function transferFrom(address _from, address _to, uint256 _amount, bytes calldata _data) external returns(bool) {
        address _spender = msg.sender;

        _spendAllowance(_from, _spender, _amount);

        _transfer(_from, _to, _amount, _data);

        return true;
    }

    function bondStatus() external view returns(BondStatus) {
        return _bondStatus;
    }

    function listOfInvestors() external view returns(IssueData[] memory) {
        return _listOfInvestors;
    }

    function bondInfo() public view returns(Bond memory) {
        return _bonds[bondISIN];
    }
    
    function issuerInfo() public view returns(Issuer memory) {
        return _issuer[bondISIN];
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
        
        _bonds[bondISIN] = _bondInfo;
        _bonds[bondISIN].issueDate = block.timestamp;
        _bondStatus = BondStatus.ISSUED;

        uint256 _maturityDate = _bonds[bondISIN].maturityDate;

        require(_maturityDate > block.timestamp, "ERC7092: INVALID_MATURITY_DATE");
        require(volume == _issueVolume, "ERC7092: INVALID_ISSUE_VOLUME");

        emit BondIssued(_issueData, _bondInfo);
    }

    function _redeem(IssueData[] memory _bondsData) internal virtual {
        uint256 _maturityDate = _bonds[bondISIN].maturityDate;
        require(block.timestamp > _maturityDate, "ERC2721: WAIT_MATURITY");

        for(uint256 i; i < _bondsData.length; i++) {
            if(_principals[_bondsData[i].investor] != 0) {
                _principals[_bondsData[i].investor] = 0;
            }
        }

        _bondStatus = BondStatus.REDEEMED;
        emit BondRedeemed();
    }

    function _approve(address _owner, address _spender, uint256 _amount) internal virtual {
        require(_owner != address(0), "ERC7092: OWNER_ZERO_ADDRESS");
        require(_spender != address(0), "ERC7092: SPENDER_ZERO_ADDRESS");
        require(_amount > 0, "ERC7092: INVALID_AMOUNT");
        require(block.timestamp < _bonds[bondISIN].maturityDate, "ERC7092: BONDS_MATURED");

        uint256 _balance = _principals[_owner] / _bonds[bondISIN].denomination;
        uint256 _denomination = _bonds[bondISIN].denomination;

        require(_amount <= _balance, "ERC7092: INSUFFICIENT_BALANCE");
        require((_amount * _denomination) % _denomination == 0, "ERC7092: INVALID_AMOUNT");

        uint256 _approval = _allowed[_owner][_spender];

        _allowed[_owner][_spender]  = _approval + _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _decreaseAllowance(address _owner, address _spender, uint256 _amount) internal virtual {
        require(_owner != address(0), "ERC7092: OWNER_ZERO_ADDRESS");
        require(_spender != address(0), "ERC7092: SPENDER_ZERO_ADDRESS");
        require(_amount > 0, "ERC7092: INVALID_AMOUNT");

        uint256 _allowance = _allowed[_owner][_spender];
        uint256 _denomination = _bonds[bondISIN].denomination;

        require(block.timestamp < _bonds[bondISIN].maturityDate, "ERC7092: BONDS_MATURED");
        require(_amount <= _allowance, "ERC7092: NOT_ENOUGH_APPROVAL");
        require((_amount * _denomination) % _denomination == 0, "ERC7092: INVALID_AMOUNT");

        _allowed[_owner][_spender]  = _allowance - _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) internal virtual {
        require(_from != address(0), "ERC7092: OWNER_ZERO_ADDRESS");
        require(_to != address(0), "ERC7092: SPENDER_ZERO_ADDRESS");
        require(_amount > 0, "ERC7092: INVALID_AMOUNT");

        uint256 principal = _principals[_from];
        uint256 _denomination = _bonds[bondISIN].denomination;
        uint256 _balance = principal / _denomination;

        require(block.timestamp < _bonds[bondISIN].maturityDate, "ERC7092: BONDS_MATURED");
        require(_amount <= _balance, "ERC7092: INSUFFICIENT_BALANCE");
        require((_amount * _denomination) % _denomination == 0, "ERC7092: INVALID_AMOUNT");

        _beforeBondTransfer(_from, _to, _amount, _data);

        uint256 principalTo = _principals[_to];

        unchecked {
            uint256 _principalToTransfer = _amount * _denomination;

            _principals[_from] = principal - _principalToTransfer;
            _principals[_to] = principalTo + _principalToTransfer;
        }

        emit Transfer(_from, _to, _amount);

        _afterBondTransfer(_from, _to, _amount, _data);
    }

    function _spendAllowance(address _from, address _spender, uint256 _amount) internal virtual {
        uint256 currentAllowance = _allowed[_from][_spender];
        require(_amount <= currentAllowance, "ERC7092: INSUFFICIENT_ALLOWANCE");

        unchecked {
            _allowed[_from][_spender] = currentAllowance - _amount;
        }
   }

   function _beforeBondTransfer(
    address _from,
    address _to,
    uint256 _amount,
    bytes calldata _data
   ) internal virtual {}

    function _afterBondTransfer(
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) internal virtual {}
}
