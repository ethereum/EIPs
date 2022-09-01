pragma solidity ^0.4.24;




contract ERC20Mockup {
    mapping(address => uint256) _balances;
    uint256 _totalSupply;
    address _owner;

    constructor(address initialAccount, uint256 initialBalance) {
        _owner = initialAccount;
        _totalSupply = initialBalance;
        _balances[initialAccount] = initialBalance;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
    }
    /*
      From there, escrow related function
    */
    function escrowFund(address to, uint256 amount) public returns (bool) {
        bool res = ERC20Mockup(to).escrowFund(msg.sender, amount);
        require(res, "Fund Failed");
        _transfer(msg.sender, to, amount);

        return true;
    }
    function escrowRefund(address to, uint256 amount) public returns (bool) {
        bool res = ERC20Mockup(to).escrowRefund(msg.sender, amount);
        require(res, "Refund Failed");
        _transfer(to, msg.sender, amount);
        return true;
    }
}
