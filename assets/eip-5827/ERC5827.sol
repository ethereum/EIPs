// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "./IERC5827.sol";

contract ERC5827 is ERC20, IERC5827 {
    struct RenewableAllowance {
        uint256 amount;
        uint192 recoveryRate;
        uint64 lastUpdated;
    }

    // owner => spender => renewableAllowance
    mapping(address => mapping(address => RenewableAllowance))
        private rAllowance;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {}

    function approve(
        address _spender,
        uint256 _value
    ) public override(ERC20, IERC5827) returns (bool success) {
        address owner = _msgSender();
        _approve(owner, _spender, _value, 0);
        return true;
    }

    function approveRenewable(
        address _spender,
        uint256 _value,
        uint256 _recoveryRate
    ) public override returns (bool success) {
        address owner = _msgSender();
        _approve(owner, _spender, _value, _recoveryRate);
        return true;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _recoveryRate
    ) internal virtual {
        require(
            _recoveryRate <= _value,
            "recoveryRate must be less than or equal to value"
        );

        rAllowance[_owner][_spender] = RenewableAllowance({
            amount: _value,
            recoveryRate: uint192(_recoveryRate),
            lastUpdated: uint64(block.timestamp)
        });

        _approve(_owner, _spender, _value);
        emit RenewableApproval(_owner, _spender, _value, _recoveryRate);
    }

    /// @notice fetch amounts spendable by _spender
    /// @return remaining allowance at the current point in time
    function allowance(
        address _owner,
        address _spender
    ) public view override(ERC20, IERC5827) returns (uint256 remaining) {
        return _remainingAllowance(_owner, _spender);
    }

    /// @dev returns the sum of two uint256 values, saturating at 2**256 - 1
    function saturatingAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return type(uint256).max;
            return c;
        }
    }

    function _remainingAllowance(
        address _owner,
        address _spender
    ) private view returns (uint256) {
        RenewableAllowance memory a = rAllowance[_owner][_spender];
        uint256 remaining = super.allowance(_owner, _spender);

        uint256 recovered = uint256(a.recoveryRate) *
            uint64(block.timestamp - a.lastUpdated);
        uint256 remainingAllowance = saturatingAdd(remaining, recovered);
        return remainingAllowance > a.amount ? a.amount : remainingAllowance;
    }

    /// @notice fetch approved max amount and recovery rate
    /// @return amount initial and maximum allowance given to spender
    /// @return recoveryRate recovery amount per second
    function renewableAllowance(
        address _owner,
        address _spender
    ) public view returns (uint256 amount, uint256 recoveryRate) {
        RenewableAllowance memory a = rAllowance[_owner][_spender];
        return (a.amount, uint256(a.recoveryRate));
    }

    /// @notice transfers base token with renewable allowance logic applied
    /// @param from owner of base token
    /// @param to recipient of base token
    /// @param amount amount to transfer
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override(ERC20, IERC5827) returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual override {
        (uint256 maxAllowance, ) = renewableAllowance(owner, spender);
        if (maxAllowance != type(uint256).max) {
            uint256 currentAllowance = _remainingAllowance(owner, spender);
            if (currentAllowance < amount) {
                revert InsufficientRenewableAllowance({
                    available: currentAllowance
                });
            }

            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
            rAllowance[owner][spender].lastUpdated = uint64(block.timestamp);
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return interfaceId == type(IERC5827).interfaceId;
    }
}
