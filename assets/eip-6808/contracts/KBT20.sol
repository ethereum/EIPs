// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import "./IKBT20.sol";

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract KBT20 is IKBT20, ERC20, Ownable {
    mapping(address => AccountHolderBindings) private _holderAccounts;
    mapping(address => FirstAccountBindings) private _firstAccounts;
    mapping(address => SecondAccountBindings) private _secondAccounts;

    mapping(address => TransferConditions) private _transferConditions;
    mapping(address => ApprovalConditions) private _approvalConditions;

    mapping(address => mapping(address => uint256))
        private _numberOfTransfersAllowed;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {}

    function addBindings(
        address _keyWallet1,
        address _keyWallet2
    ) external returns (bool) {
        address sender = _msgSender();
        require(balanceOf(sender) > 0, "[200] KBT20: Wallet is not a holder");
        require(
            _holderAccounts[sender].firstWallet == address(0) &&
                _holderAccounts[sender].secondWallet == address(0),
            "[201] KBT20: Key wallets are already filled"
        );
        require(
            _keyWallet1 != address(0) && _keyWallet2 != address(0),
            "[202] KBT20: Does not follow 0x standard"
        );
        require(
            _keyWallet1 != _keyWallet2,
            "[205] KBT20: Key wallet 1 must be different than key wallet 2"
        );
        require(
            _keyWallet1 != sender,
            "[206] KBT20: Key wallet 1 must be different than the sender"
        );
        require(
            sender != _keyWallet2,
            "[207] KBT20: Key wallet 2 must be different than the sender"
        );
        require(
            _firstAccounts[_keyWallet1].accountHolderWallet == address(0),
            "[203] KBT20: Key wallet 1 is already registered"
        );
        require(
            _secondAccounts[_keyWallet2].accountHolderWallet == address(0),
            "[204] KBT20: Key wallet 2 is already registered"
        );

        _holderAccounts[sender] = AccountHolderBindings({
            firstWallet: _keyWallet1,
            secondWallet: _keyWallet2
        });

        _firstAccounts[_keyWallet1] = FirstAccountBindings({
            accountHolderWallet: sender,
            secondWallet: _keyWallet2
        });

        _secondAccounts[_keyWallet2] = SecondAccountBindings({
            accountHolderWallet: sender,
            firstWallet: _keyWallet1
        });

        emit AccountSecured(sender, balanceOf(sender));

        return true;
    }

    function getBindings(
        address _account
    ) external view returns (AccountHolderBindings memory) {
        return _holderAccounts[_account];
    }

    function resetBindings() external returns (bool) {
        address accountHolder = _getAccountHolder();
        require(
            accountHolder != address(0),
            "[300] KBT20: Key authorization failure"
        );

        delete _firstAccounts[_holderAccounts[accountHolder].firstWallet];
        delete _secondAccounts[_holderAccounts[accountHolder].secondWallet];
        delete _holderAccounts[accountHolder];

        emit AccountResetBinding(accountHolder);

        return true;
    }

    function safeFallback() external returns (bool) {
        address accountHolder = _getAccountHolder();
        address otherSecureWallet = _getOtherSecureWallet();
        require(
            accountHolder != address(0),
            "[400] KBT20: Key authorization failure"
        );

        _transfer(accountHolder, otherSecureWallet, balanceOf(accountHolder));

        emit SafeFallbackActivated(accountHolder);

        return true;
    }

    function allowTransfer(
        uint256 _amount,
        uint256 _time,
        address _to,
        bool _allFunds
    ) external virtual returns (bool) {
        address accountHolder = _getAccountHolder();

        require(
            accountHolder != address(0),
            "[500] KBT20: Key authorization failure"
        );
        require(
            balanceOf(accountHolder) >= _amount,
            "[501] KBT20: Not enough tokens"
        );

        _time = _time > 0 ? (block.timestamp + _time) : 0;

        _transferConditions[accountHolder] = TransferConditions({
            amount: _amount,
            time: _time,
            to: _to,
            allFunds: _allFunds
        });

        emit AccountEnabledTransfer(
            accountHolder,
            _amount,
            _time,
            _to,
            _allFunds
        );

        return true;
    }

    function getTransferableFunds(
        address _account
    ) external view returns (TransferConditions memory) {
        return _transferConditions[_account];
    }

    function allowApproval(
        uint256 _time,
        uint256 _numberOfTransfers
    ) external virtual override returns (bool) {
        address accountHolder = _getAccountHolder();
        require(
            accountHolder != address(0),
            "[600] KBT20: Key authorization failure"
        );

        _time = block.timestamp + _time;

        _approvalConditions[accountHolder].time = _time;
        _approvalConditions[accountHolder]
            .numberOfTransfers = _numberOfTransfers;

        emit AccountEnabledApproval(accountHolder, _time, _numberOfTransfers);

        return true;
    }

    function getApprovalConditions(
        address _account
    ) external view returns (ApprovalConditions memory) {
        return _approvalConditions[_account];
    }

    function getNumberOfTransfersAllowed(
        address _account,
        address _spender
    ) external view returns (uint256) {
        return _numberOfTransfersAllowed[_account][_spender];
    }

    function isSecureWallet(address _account) public view returns (bool) {
        return
            _holderAccounts[_account].firstWallet != address(0) &&
            _holderAccounts[_account].secondWallet != address(0);
    }

    //region ERC20 overrides

    function transfer(
        address _to,
        uint256 _amount
    ) public virtual override returns (bool) {
        address _owner = _msgSender();

        if (isSecureWallet(_owner)) {
            require(
                _hasAllowedTransfer(_owner, _amount, _to),
                "[100] KBT20: Sender is a secure wallet and doesn't have approval for the amount"
            );
        }

        _transfer(_owner, _to, _amount);

        delete _transferConditions[_owner];

        return true;
    }

    function approve(
        address _spender,
        uint256 _amount
    ) public virtual override returns (bool) {
        address _owner = _msgSender();
        if (isSecureWallet(_owner)) {
            require(
                _approvalConditions[_owner].time > 0,
                "[101] KBT20: Spending of funds is not authorized."
            );
            require(
                _isApprovalAllowed(_owner),
                "[102] KBT20: Time has expired for the spending of funds"
            );
        }

        _approve(_owner, _spender, _amount);

        _numberOfTransfersAllowed[_owner][_spender] = _approvalConditions[
            _owner
        ].numberOfTransfers;

        delete _approvalConditions[_owner];

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(_from, spender, _amount);
        _transfer(_from, _to, _amount);

        if (_numberOfTransfersAllowed[_from][spender] != 0) {
            if (_numberOfTransfersAllowed[_from][spender] == 1) {
                _approve(_from, spender, 0);
            }
            _numberOfTransfersAllowed[_from][spender] -= 1;
        }
        return true;
    }

    function increaseAllowance(
        address _spender,
        uint256 _addedValue
    ) public virtual override returns (bool) {
        address _owner = _msgSender();
        require(
            _approvalConditions[_owner].time > 0,
            "[101] KBT20: Spending of funds is not authorized."
        );
        require(
            _isApprovalAllowed(_owner),
            "[102] KBT20: Time has expired for the spending of funds"
        );

        _approve(_owner, _spender, allowance(_owner, _spender) + _addedValue);

        delete _approvalConditions[_owner];

        return true;
    }

    function decreaseAllowance(
        address _spender,
        uint256 _subtractedValue
    ) public virtual override returns (bool) {
        address _owner = _msgSender();
        require(
            _approvalConditions[_owner].time > 0,
            "[101] KBT20: Spending of funds is not authorized."
        );
        require(
            _isApprovalAllowed(_owner),
            "[102] KBT20: Time has expired for the spending of funds"
        );

        uint256 currentAllowance = allowance(_owner, _spender);
        require(
            currentAllowance >= _subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_owner, _spender, currentAllowance - _subtractedValue);
        }

        delete _approvalConditions[_owner];

        return true;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // region update secureAccounts
        if (isSecureWallet(from) && balanceOf(from) == 0) {
            delete _firstAccounts[_holderAccounts[from].firstWallet];
            delete _secondAccounts[_holderAccounts[from].secondWallet];
            delete _holderAccounts[from];
        }
        // endregion

        if (balanceOf(from) == 0) {
            emit Egress(from, amount);
        }

        if (balanceOf(to) == amount) {
            emit Ingress(to, amount);
        }
    }

    // endregion

    function _hasAllowedTransfer(
        address _account,
        uint256 _amount,
        address _to
    ) internal view returns (bool) {
        TransferConditions memory conditions = _transferConditions[_account];

        if (conditions.allFunds) {
            return true;
        }

        if (
            (conditions.amount == 0 &&
                conditions.time == 0 &&
                conditions.to == address(0)) ||
            (conditions.amount > 0 && conditions.amount < _amount) ||
            (conditions.time > 0 && conditions.time < block.timestamp) ||
            (conditions.to != address(0) && conditions.to != _to)
        ) {
            return false;
        }

        return true;
    }

    function _isApprovalAllowed(address account) internal view returns (bool) {
        return _approvalConditions[account].time >= block.timestamp;
    }

    function _getAccountHolder() internal view returns (address) {
        address sender = _msgSender();
        return
            _firstAccounts[sender].accountHolderWallet != address(0)
                ? _firstAccounts[sender].accountHolderWallet
                : (
                    _secondAccounts[sender].accountHolderWallet != address(0)
                        ? _secondAccounts[sender].accountHolderWallet
                        : address(0)
                );
    }

    function _getOtherSecureWallet() internal view returns (address) {
        address sender = _msgSender();
        address accountHolder = _getAccountHolder();

        return
            _holderAccounts[accountHolder].firstWallet == sender
                ? _holderAccounts[accountHolder].secondWallet
                : _holderAccounts[accountHolder].firstWallet;
    }
}
