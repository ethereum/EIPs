// SPDX-License-Identifier: CC0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./IERC888.sol";
import "./IERC888Metadata.sol";

contract ERC888 is Context, IERC888, IERC888Metadata, ERC165 {
    mapping(address => uint256) private _balances;

    mapping(address => bool) private _participants;

    uint256 private _totalSupply;

    string private _name;
    string private _description;
    address private _operator;

    /**
     * @notice Sets the values for {name} and {symbol}.
     * @dev Both two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory description_, address operator_) {
        _name = name_;
        _description = description_;
        _operator = operator_;
        _participants[_operator] = true;
    }

    /**
     *
     * External Functions
     *
     */

    /**
     * @notice Returns the name of the EXP token.
     * @return string The name of the EXP token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the description of the EXP token,
     * usually a one-line description.
     * @return string The description of the EXP token.
     */
    function description() public view virtual override returns (string memory) {
        return _description;
    }

    /**
     * @notice Returns the current operator of the EXP token,
     * @return address The current operator of the EXP token.
     */
    function operator() public view virtual returns (address) {
        return _operator;
    }

    /**
     * @notice Returns the total supply of EXP tokens.
     * @dev Result includes inactive accounts, but not destroyed tokens.
     * @return uint256 The total supply of EXP tokens.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Returns the EXP balance of the account.
     * @param account The address to query.
     * @return uint256 The EXP balance of the account.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Returns the participation status of the account.
     * @param account The address to query.
     * @return bool The participation status of the queried account.
     */
    function participationOf(address account) public view virtual returns (bool) {
        return _participants[account];
    }

    /**
     * @notice Transfer `amount` EXP to an account from zero address. 
     * Equivalent to minting.
     * @dev Emits {Transfer} event if successful.
     * Throws if:  
     * - Sender is not operator 
     * - `to` address is not participating
     * @param to The address of the recipient.
     * @param amount The amount to be transferred.
     */
    function transfer(address to, uint256 amount) public virtual override {
        _transfer(address(0), to, amount);
    }

    /**
     * @notice Transfer `amount` EXP to an account. Equivalent to minting.
     * @dev Emits {Transfer} event if successful.
     * Throws if:  
     * - Sender is not operator 
     * - `to` address is not participating
     * @param from The address from which to transfer.
     * @param to The address of the recipient.
     * @param amount The amount to be transferred.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override {
        _transfer(from, to, amount);
    }    

    /**
     * @notice Sets approval of participant EXP acceptance.
     * @dev Throws if msg.sender is not the address in question.
     */
    function approve(address participant, bool participation) public virtual override {
        require(_msgSender() == participant);
        _approve(participant, participation);
    }

    /**
    * @notice Assigns a new operator address.
    * @dev Throws if sender is not operator or `newOperator` equals current `_operator`
    * @param newOperator Address to reassign operator role.
    */
    function setOperator(address newOperator) public virtual override {
        _setOperator(newOperator);
    }

    /**
     *
     * Internal Functions
     *
     */

    /**
     * @notice Moves `amount` of tokens from `from` address to `to` address.
     * @dev Throws if sender is not operator.
     * Throws if `to` is not participating.
     * Emits a {Transfer} event.
     * @param from Address from which to transfer. If zero address, then add to totalSupply.
     * @param to Address to which to transfer.
     * @param amount Number of EXP transfer.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(_msgSender() == _operator, "Sender is not the operator.");
        require(_participants[to] == true, "`to` address is not an active participant.");

        if (from == address(0)) {
            _totalSupply += amount;
        } else {
            require(_balances[from] >= amount, "{from} address holds less EXP than {amount}.");
            _balances[from] -= amount;
        }

        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    /**
     * @notice Sets approval status for `participant`.
     * @dev Throws if sender is not `participant`.
     * Emits a {Approval} event.
     * @param participant Address for which to set approval.
     * @param participation Requested approval status.
     */
    function _approve(address participant, bool participation) internal virtual {
        require(_msgSender() == participant, "Sender is not {participant}.");
        require(_msgSender() != _operator, "Operator cannot change participation");
        require(_participants[participant] != participation, "Participant already has {participation} status");
        _participants[participant] = participation;
        emit Approval(participant, participation);
    }

    /**
     * @notice Assign a new operator.
     * @dev Throws is sender is not current operator.
     * Emits {Appointment} event.
     * @param newOperator address to be assigned operator authority.
     */
    function _setOperator(address newOperator) internal virtual {
        require(_msgSender() == _operator, "Sender is not operator.");
        require(_operator != newOperator, "Address is already assigned as operator");
        _operator = newOperator;
        emit Appointment(newOperator);
    }

}