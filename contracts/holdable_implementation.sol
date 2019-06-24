pragma solidity ^0.5.0;

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol';
import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol';
import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";


contract HoldableToken is ERC20, ERC20Mintable, Ownable{

   using SafeMath for uint256;

        enum HoldStatusCode {
        Nonexistent,
        Ordered,
        Executed,
        ReleasedByNotary,
        ReleasedByPayee,
        ReleasedOnExpiration
    }

    struct Hold {
        address issuer;
        address origin;
        address target;
        address notary;
        bool expires;
        uint256 expiration;
        uint256 amount;
        HoldStatusCode status;
    }

    mapping(string => Hold) private holds;
    mapping(address => uint256) private heldBalance;
    mapping(address => address[]) private operatorsAuthorized;
    mapping(address => mapping(address => uint256)) private indexOperator;

    uint256 private _totalHeldBalance;
    
    
    event HoldCreated(address indexed holdIssuer, string  operationId, address from, address to, address indexed notary, uint256 value, bool expires, uint256 expiration);
    event HoldExecuted(address indexed holdIssuer, string operationId, address indexed notary, uint256 heldValue, uint256 transferredValue);
    event HoldReleased(address indexed holdIssuer, string operationId, HoldStatusCode status);
    event HoldRenewed(address indexed holdIssuer, string operationId, uint256 oldExpiration, uint256 newExpiration);
    event AuthorizedHoldOperator(address indexed operator, address indexed account);
    event RevokedHoldOperator(address indexed operator, address indexed account);

    
    
    function hold(string calldata operationId, address to, address notary, uint256 value, uint256 timeToExpiration) external returns (bool){

        require(holds[operationId].amount == 0, "This operationId already exists");
        require(value <= balanceOf(msg.sender), "Amount of the hold can't be greater than the balance of the origin");

        holds[operationId].issuer = msg.sender;
        holds[operationId].origin = msg.sender;
        holds[operationId].target = to;
        holds[operationId].notary = notary;
        holds[operationId].amount = value;
        holds[operationId].status = HoldStatusCode.Ordered;

        if(timeToExpiration == 0){
            holds[operationId].expires = false;
            holds[operationId].expiration = 0;
        }else{
            holds[operationId].expires = true;
            holds[operationId].expiration = block.timestamp.add(timeToExpiration);
        }

        heldBalance[msg.sender] = heldBalance[msg.sender].add(value);


        _totalHeldBalance = _totalHeldBalance.add(value);

        emit HoldCreated(
            msg.sender,
            operationId,
            msg.sender,
            to,
            notary,
            value,
            holds[operationId].expires,
            timeToExpiration
        );
        return true;
    }
    
    
    function holdFrom(string calldata operationId, address from, address to, address notary, uint256 value, uint256 timeToExpiration) external returns (bool){

        require(holds[operationId].amount == 0, "This operationId already exists");
        require(value <= balanceOf(from), "Amount of the hold can't be greater than the balance of the origin");
        require (indexOperator[from][msg.sender] != 0, "This operator is not authorized"); 
        

        holds[operationId].issuer = msg.sender;
        holds[operationId].origin = from;
        holds[operationId].target = to;
        holds[operationId].notary = notary;
        holds[operationId].amount = value;
        holds[operationId].status = HoldStatusCode.Ordered;

        if(timeToExpiration == 0){
            holds[operationId].expires = false;
            holds[operationId].expiration = 0;
        }else{
            holds[operationId].expires = true;
            holds[operationId].expiration = block.timestamp.add(timeToExpiration);
        }

        heldBalance[from] = heldBalance[from].add(value);

        _totalHeldBalance = _totalHeldBalance.add(value);
        
        bool expires = holds[operationId].expires; //I did this line because it didn't allow me to put more local vaiables on the event "stack too deep"

        emit HoldCreated(
            msg.sender,
            operationId,
            from,
            to,
            notary,
            value,
            expires,
            timeToExpiration
        );
        return true;
    }
    
    
    function releaseHold(string calldata operationId) external returns (bool){

        require(holds[operationId].status == HoldStatusCode.Ordered, "This hold has already been released or executed");
        if(block.timestamp < holds[operationId].expiration || holds[operationId].expires == false){
            require(holds[operationId].notary == msg.sender || holds[operationId].target == msg.sender, "The hold can only be released by the notary or the payee");
        }

        heldBalance[holds[operationId].origin] = heldBalance[holds[operationId].origin].sub(holds[operationId].amount);
        _totalHeldBalance = _totalHeldBalance.sub(holds[operationId].amount);

        if(block.timestamp >= holds[operationId].expiration && holds[operationId].expires == true){
            holds[operationId].status = HoldStatusCode.ReleasedOnExpiration;
            emit HoldReleased(holds[operationId].issuer, operationId, HoldStatusCode.ReleasedOnExpiration);
        }
        if(block.timestamp < holds[operationId].expiration || holds[operationId].expires == false){
            if(holds[operationId].notary == msg.sender){
                holds[operationId].status = HoldStatusCode.ReleasedByNotary;
                emit HoldReleased(holds[operationId].issuer, operationId, HoldStatusCode.ReleasedByNotary);
            }
            if(holds[operationId].target == msg.sender){
                holds[operationId].status = HoldStatusCode.ReleasedByPayee;
                emit HoldReleased(holds[operationId].issuer, operationId, HoldStatusCode.ReleasedByPayee);
            }
        }
        return true;
        
    }
    
    
    function executeHold(string calldata operationId, uint256 value) external returns (bool){
        
        require(holds[operationId].status == HoldStatusCode.Ordered, "This hold has already been released or executed");
        require(block.timestamp < holds[operationId].expiration || holds[operationId].expires == false, "This hold has already expired");
        require(holds[operationId].notary == msg.sender, "The hold can only be executed by the notary");
        require(value <= holds[operationId].amount, "The value should be equal or lower than the held amount");

        heldBalance[holds[operationId].origin] = heldBalance[holds[operationId].origin].sub(holds[operationId].amount);
        _totalHeldBalance = _totalHeldBalance.sub(holds[operationId].amount);

        _transfer(holds[operationId].origin, holds[operationId].target, value);

        holds[operationId].status = HoldStatusCode.Executed;
        
        emit HoldExecuted(holds[operationId].issuer, operationId, holds[operationId].notary, holds[operationId].amount, value);
        return true;
    }
    
    
    function renewHold(string calldata operationId, uint256 timeToExpiration) external returns (bool){

        require(holds[operationId].status == HoldStatusCode.Ordered, "This hold has already been released or executed");
        require(block.timestamp < holds[operationId].expiration || holds[operationId].expires == false, "This hold has already expired");
        require(holds[operationId].origin == msg.sender || holds[operationId].issuer == msg.sender, "The hold can only be renewed by the issuer or the payer");

        uint256 oldExpiration = holds[operationId].expiration;
        if(timeToExpiration == 0){
            holds[operationId].expires = false;
            holds[operationId].expiration = 0;
        }else{
            holds[operationId].expires = true;
            holds[operationId].expiration = timeToExpiration;
        }

        emit HoldRenewed(holds[operationId].issuer, operationId, oldExpiration, timeToExpiration);
        return true;
    }
    
    
    function retrieveHoldData(string calldata operationId) external view returns (address from, address to, address notary, uint256 value, bool expires, uint256 expiration, HoldStatusCode status){ //maybe also the issuer??

        return (holds[operationId].origin, holds[operationId].target, holds[operationId].notary, holds[operationId].amount, holds[operationId].expires, holds[operationId].expiration, holds[operationId].status);
    }
    
    
    function balanceOnHold(address account) external view returns (uint256){
        return heldBalance[account];
    }
    
    
    function netBalanceOf(address account) external view returns (uint256){
        return balanceOf(account).sub(heldBalance[account]);
    }
    
    
    function totalSupplyOnHold() external view returns (uint256){
        return _totalHeldBalance;
    }
    
    
    function authorizeHoldOperator(address operator) external returns (bool){
        
        require (indexOperator[msg.sender][operator] == 0, "This operator is already authorized"); 
        
        operatorsAuthorized[msg.sender].push(operator);
        indexOperator[msg.sender][operator] = operatorsAuthorized[msg.sender].length;
        
        emit AuthorizedHoldOperator(operator, msg.sender);
        return true;
    }
    
    
    function revokeHoldOperator(address operator) external returns (bool){
        
        require (indexOperator[msg.sender][operator] != 0, "This operator is already not authorized");

        for (uint i = indexOperator[msg.sender][operator]-1; i<operatorsAuthorized[msg.sender].length-1; i++){
            operatorsAuthorized[msg.sender][i] = operatorsAuthorized[msg.sender][i+1];
            indexOperator[msg.sender][operatorsAuthorized[msg.sender][i]]--;
        }
        delete operatorsAuthorized[msg.sender][operatorsAuthorized[msg.sender].length-1];
        operatorsAuthorized[msg.sender].length--;
        indexOperator[msg.sender][operator] = 0;
        
        emit RevokedHoldOperator(operator, msg.sender);
        return true;
    }






   /**
    function _hold(string calldata operationId, address issuer, address from, address to, address notary, uint256 value, uint256 timeToExpiration) external returns (bool){

        
    }
  
    **/

}