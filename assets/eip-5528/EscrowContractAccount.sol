pragma solidity ^0.4.24;

import "./ERC20Mockup.sol";


contract ErcEscrowAccount {
    struct BalanceData {
        uint256 seller;
        uint256 buyer;
    }

    enum State { Inited, Running, Success, Failed }

    struct EscrowStatus {
        uint256 numberOfBuyer;
        uint256 fundTotal;
        uint256 fundFilled;
        State   state;
    }
    mapping(address => BalanceData) _balances;

    address _addrSeller;
    address _addrBuyer;
    address _addrEscrow;
    address _addrCreator;

    EscrowStatus _status;

    constructor(uint256 fundAmount, address sellerContract, address buyerContract) {

      //require(sellerContract.code.length > 0, "seller is not contract");
      //require(buyerContract.code.length > 0, "buyer is not contract");

      _addrBuyer = buyerContract;
      _addrSeller = sellerContract;

      _status.numberOfBuyer = 0;
      _status.fundTotal = fundAmount;
      _status.fundFilled = 0;

      _addrEscrow = address(this);
      _addrCreator = msg.sender;
      _status.state = State.Inited;
    }


    function helper_bigInt256(uint256 _u256Val) public view returns (uint256) {
        return _u256Val;
    }

    function helper_numberOfBuyers() public view returns (uint256) {
        return _status.numberOfBuyer;
    }

    function _updateRunningState() {
        if(_status.state == State.Running){
            if(_status.numberOfBuyer == 2){
                _status.state = State.Success;
            }
        }
    }

    function escrowStatus() public view returns (string) {
        if(_status.state == State.Inited){
          return "init";
        }else if(_status.state == State.Running){
          return "Running";
        }else if(_status.state == State.Success){
          return "Success";
        }else if(_status.state == State.Failed){
          return "Failed";
        }
        return "unknown state";
    }


    function balanceOf(address account) public view returns (uint256) {
        return _balances[account].buyer;
    }

    function escrowBalanceOf(address account) public view returns (uint256 o_buyer, uint256 o_seller) {
        o_buyer = _balances[account].buyer;
        o_seller = _balances[account].seller;
    }

    function escrowFund(address to, uint256 amount) public returns (bool) {
        require(amount > 0, "amount is too small");
        if(msg.sender == _addrSeller){

            require(_status.state == State.Inited, "must be init state");
            require(to == _addrCreator, "to is only with creator");
            require(amount == _status.fundTotal, "amount must be total fund");
            require(_status.fundFilled == 0, "fund filled must be zero");

            _status.fundFilled = amount;

            _balances[to].seller = _balances[to].seller + amount;
            _balances[to].buyer = 0;
            _status.state = State.Running;

        }else if(msg.sender == _addrBuyer){
            require(_status.state == State.Running, "must be running state");
            require(_status.fundTotal > 0, "escrow might be not started or already finished");
            require(_status.fundFilled == _status.fundTotal, "fund does not filled yet");

            // TODO: this logic is only for 1:1 exchange rate
            require(amount <= _balances[_addrCreator].seller, "no more token left to exchange");

            _balances[_addrCreator].seller = _balances[_addrCreator].seller - amount;
            _balances[_addrCreator].buyer = _balances[_addrCreator].buyer + amount;

            if(_balances[to].seller == 0){
                _status.numberOfBuyer = _status.numberOfBuyer + 1;
            }
            _balances[to].seller = _balances[to].seller + amount;
            _balances[to].buyer = _balances[to].buyer + amount;

            _updateRunningState();
        }else{
            require(false, "Todo other cases");
        }



        return true;
    }

    function escrowRefund(address to, uint256 amount) public returns (bool) {
        require(amount > 0, "amount is too small");
        require(_status.state == State.Running || _status.state == State.Failed, "must be running state to refund");
        require(msg.sender == _addrBuyer, "must be buyer contract to refund");
        require(_balances[to].buyer >= amount, "buyer fund is not enough to refund");


        _balances[to].buyer = _balances[to].buyer - amount;
        _balances[to].seller = _balances[to].seller - amount;

        _balances[_addrCreator].seller = _balances[_addrCreator].seller + amount;
        _balances[_addrCreator].buyer = _balances[_addrCreator].buyer - amount;

        if(_balances[to].buyer == 0){
            _status.numberOfBuyer = _status.numberOfBuyer - 1;
        }

        _updateRunningState();
        return true;
    }

    function escrowWithdraw() public returns (bool) {
        address from = msg.sender;

        if(from == _addrCreator){
            if(_status.state == State.Success){
                ERC20Mockup(_addrBuyer).transfer(from, _balances[from].buyer);
                ERC20Mockup(_addrSeller).transfer(from, _balances[from].seller);

            }else if(_status.state == State.Failed){
                ERC20Mockup(_addrSeller).transfer(from, _status.fundFilled);
            }else{
                require(false, "invalid state for seller withdraw");
            }
        }else{
            require(_status.state == State.Success, "withdraw is only in success, otherwise use refund");
            ERC20Mockup(_addrSeller).transfer(from, _balances[from].seller);
        }

        delete _balances[from];
        return true;
    }
    
}
