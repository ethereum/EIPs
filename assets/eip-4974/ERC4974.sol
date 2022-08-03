// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;
import "./IERC4974.sol";
import "./IERC4974Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * See {IERC4974}
 * Implements the ERC4974 Metadata extension.
 */
contract ERC4974 is Context, IERC165, IERC4974, IERC4974Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _participants;
    address private _operator;
    uint256 private _totalSupply;
    string private _name;
    string private _description;

    /**
     * @notice Sets the values for {name} and {symbol}.
     * @dev Name and description are both immutable: they can only be set once during
     * construction. Operator cannot be the zero address.
     */
    constructor(string memory name_, string memory description_, address operator_) {
    // constructor(address operator_) {
        require(operator_ != address(0), "Operator cannot be the zero address.");
        _name = name_;
        _description = description_;
        _operator = operator_;
        _participants[_operator] = true;
        _participants[address(0)] = true;
    }

    /**
     *
     * External Functions
     *
     */

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC4974).interfaceId ||
            interfaceId == type(IERC4974Metadata).interfaceId ||
            supportsInterface(interfaceId);
    }

    /**
    * @notice Assigns a new operator address.
    * @dev Throws if sender is not operator or `newOperator` equals current `_operator`
    * @param newOperator Address to reassign operator role.
    */
    function setOperator(address newOperator) external virtual override {
        _setOperator(newOperator);
    }

    /**
     * @notice Sets participation status for an address.
     * @dev Throws if msg.sender is not the address in question.
     */
    function setParticipation(address participant, bool participation) external virtual override {
        _participation(participant, participation);
    }

    /**
     * @notice Transfer `amount` EXP to an account.
     * @dev Emits `Transfer` event if successful.
     * Throws if:  
     * - Sender is not operator 
     * - `to` address is not participating.
     * - Zero address mints to itself.
     * @param from The address from which to transfer. Zero address for mints.
     * @param to The address of the recipient. Zero address for burns.
     * @param amount The amount to be transferred.
     */
    function transfer(address from, address to, uint256 amount) external virtual override {
        _transfer(from, to, amount);
    }

    /**
     * @notice Returns the name of the EXP token.
     * @return string The name of the EXP token.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the description of the EXP token,
     * usually a one-line description.
     * @return string The description of the EXP token.
     */
    function description() external view virtual override returns (string memory) {
        return _description;
    }

    /**
     * @notice Returns the current operator of the EXP token,
     * @return address The current operator of the EXP token.
     */
    function operator() external view virtual returns (address) {
        return _operator;
    }

    /**
     * @notice Returns the EXP balance of the account.
     * @param account The address to query.
     * @return uint256 The EXP balance of the account.
     */
    function balanceOf(address account) external view virtual override returns (uint256) {
        require(account != address(0), "Zero address has no balance.");
        return _balances[account];
    }

    /**
     * @notice Returns the participation status of the account.
     * @param account The address to query.
     * @return bool The participation status of the queried account.
     */
    function participationOf(address account) external view virtual returns (bool) {
        return _participants[account];
    }

    /**
     * @notice Returns the total supply of EXP tokens.
     * @dev Result includes inactive accounts, but not destroyed tokens.
     * @return uint256 The total supply of EXP tokens.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     *
     * Internal Functions
     *
     */

    /**
     * @notice Assign a new operator.
     * @dev Throws is sender is not current operator.
     * Emits {Appointment} event.
     * @param newOperator address to be assigned operator authority.
     */
    function _setOperator(address newOperator) internal virtual {
        require(_msgSender() == _operator, "Sender is not operator.");
        require(newOperator != address(0), "Operator cannot be the zero address.");
        require(_operator != newOperator, "{address} is already assigned as operator");
        _operator = newOperator;
        emit Appointment(newOperator);
    }

    /**
     * @notice Sets participation status for `participant`.
     * @dev Throws if sender is not `participant`.
     * Emits a {Participation} event.
     * @param participant Address for which to set participation.
     * @param participation Requested participation status.
     */
    function _participation(address participant, bool participation) internal virtual {
        require(_msgSender() == participant, "Sender is not {participant}.");
        require(_msgSender() != _operator, "Operator cannot change participation");
        require(participant != address(0), "Zero address cannot be removed.");
        require(_participants[participant] != participation, "Participant already has {participation} status");
        _participants[participant] = participation;
        emit Participation(participant, participation);
    }

    /**
     * @notice Moves `amount` of tokens from `from` address to `to` address.
     * @dev Throws if sender is not operator.
     * Throws if `to` is not participating.
     * Emits a {Transfer} event.
     * @param from Address from which to transfer. If zero address, then add to totalSupply.
     * @param to Address to which to transfer. If zero address, then subtract from totalSupply.
     * @param amount Number of EXP transfer.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(_msgSender() == _operator, "Sender is not the operator.");
        require(_participants[to] == true, "{to} address is not an active participant.");
        require(from != to, "{to} and {from} cannot be the same address.");
        if (from == address(0)) {
            _totalSupply += amount;
        } else {
            require(_balances[from] >= amount, "{from} address holds less EXP than {amount}.");
            _balances[from] -= amount;
            if (to == address(0)) {
                _totalSupply -= amount;
            }
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }
}