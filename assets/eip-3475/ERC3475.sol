// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;


import "./IERC3475.sol";
import "./utils/MathLibrary.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC3475 is IERC3475, Ownable {
    /** 
    * @notice this Struct is representing the NONCE properties as an object
    */
    struct NONCE {
        bool exists;

        // stores the values corresponding to the dates (issuance and maturity date).
        uint256[] _values; 
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        address owner;

        // supplies of this nonce
        uint256 _activeSupply;
        uint256 _burnedSupply;
        uint256 _redeemedSupply;
    }

    /**
     * @notice this Struct is representing the CLASS properties as an object
     *         and can be retrieve by the classId
     */
    struct CLASS {
        bool exists;

        // here for each class we have an array of 2 values: debt token address and period of the bond (6 months or 12 months for example)
        uint256[] _values; 
        IERC3475.METADATA[] _nonceMetadata;        
        mapping(uint256 => NONCE) nonces;

        // supplies of this class
        uint256 _activeSupply;
        uint256 _burnedSupply;
        uint256 _redeemedSupply;
    }

    mapping(address => mapping(address => bool)) operatorApprovals;

    // from classId given
    mapping(uint256 => CLASS) internal classes; 
    IERC3475.METADATA[] _classMetadata;

    /**
     * @notice Here the constructor is just to initialize a class and nonce,
     * in practice you will have a function to create new class and nonce
     */
    constructor() {
       
    }


    //  to be deployed during the initial deployement cycle
    function init() public onlyOwner  {
        // create class, in other implementation, a create class function can be added
        classes[0].exists = true;

        // define "symbol of the class";
        _classMetadata[0].title = "symbol";
        _classMetadata[0].types = "string";
        _classMetadata[0].description = "symbol of the class";

        // define "period of the class";
        _classMetadata[5].title = "period";
        _classMetadata[5].types = "int";
        _classMetadata[5].description = "details about issuance and redemption time";

        // add metadata values to the metadata structure, this value will only for the front end
        _classMetadata[0].values[0] = "DBIT Fix 6M";

        // add values to the class structure, this value can be read by the the smart contract and the front end
        classes[0]._values[5] = 180 days;


        // create nonces, in other implementation, a create nonce function can be added
        classes[0].nonces[0].exists = true;
        classes[0].nonces[1].exists = true;
        classes[0].nonces[2].exists = true;

        // write the time of maturity to nonce values, in other implementation, a create nonce function can be added
        classes[0].nonces[0]._values[0] = block.timestamp + 180 days;
        classes[0].nonces[1]._values[0] = block.timestamp + 181 days;
        classes[0].nonces[2]._values[0] = block.timestamp + 182 days;

        // define "maturity of the nonce";        
        classes[0]._nonceMetadata[0].title = "maturity";
        classes[0]._nonceMetadata[0].title = "int";
        classes[0]._nonceMetadata[0].description = "maturity date";


    }



    // WRITABLE
    function transferFrom(
        address _from,
        address _to,
        TRANSACTION[] calldata _transactions
    ) public virtual override {
        require(
            _from != address(0),
            "ERC3475: can't transfer from the zero address"
        );
        require(
            _to != address(0),
            "ERC3475: can't transfer to the zero address"
        );
        require(
                msg.sender == _from ||
                isApprovedFor(_from, msg.sender),
                "ERC3475:caller-not-owner-or-approved"
            );
        uint256 len = _transactions.length;
        for (uint256 i = 0; i < len; i++) {           
            _transferFrom(_from, _to, _transactions[i]);
        }
        emit Transfer(msg.sender, _from, _to, _transactions);
    }

    function transferAllowanceFrom(
        address _from,
        address _to,
        TRANSACTION[] calldata _transactions
    ) public virtual override {
        require(
            _from != address(0),
            "ERC3475: can't transfer from the zero address"
        );
        require(
            _to != address(0),
            "ERC3475: can't transfer to the zero address"
        );
        uint256 len = _transactions.length;
        for (uint256 i = 0; i < len; i++) {
            require(
                _transactions[i]._amount <= allowance(_from, msg.sender, _transactions[i].classId, _transactions[i].nonceId),
                "ERC3475:caller-not-owner-or-approved"
            );
            _transferAllowanceFrom(msg.sender, _from, _to, _transactions[i]);
        }
        emit Transfer(msg.sender, _from, _to, _transactions);
    }

    function issue(address _to, TRANSACTION[] calldata _transactions)
        external
        virtual
        override
    {
        uint256 len = _transactions.length;

        for (uint256 i = 0; i < len; i++) {
            require(
                classes[i].exists, 
                "ERC3475: BOND-CLASS-NOT-CREATED"
            );
            require(
                _to != address(0),
                "ERC3475: can't transfer to the zero address"
            );
            _issue(_to, _transactions[i]);
        }

        emit Issue(msg.sender, _to, _transactions);
    }

    function redeem(address _from, TRANSACTION[] calldata _transactions)
        external
        virtual
        override
    {
        require(
            _from != address(0),
            "ERC3475: can't redeem from the zero address"
        );
        require(
            msg.sender == _from ||
            isApprovedFor(_from, msg.sender),
            "ERC3475: caller-not-owner-or-approved"
        ); 
        uint256 len = _transactions.length;
        for (uint256 i = 0; i < len; i++) {
            (, uint256 progressRemaining) = getProgress(
                _transactions[i].classId,
                _transactions[i].nonceId
            );
            require(progressRemaining == 0, "ERC3475 Error: Not redeemable");
            _redeem(_from, _transactions[i]);
        }
        emit Redeem(msg.sender, _from, _transactions);
    }

    function burn(address _from, TRANSACTION[] calldata _transactions)
        external
        virtual
        override
    {
        require(
            _from != address(0),
            "ERC3475: can't burn from the zero address"
        );
         require(
              msg.sender == _from ||
              isApprovedFor(_from, msg.sender),
              "ERC3475: caller-not-owner-or-approved"
          ); 
        
        uint256 len = _transactions.length;
        for (uint256 i = 0; i < len; i++) {
            _transferFrom(_from, address(0), _transactions[i]);
        }      
        emit Burn(msg.sender, _from, _transactions);
    }

    function approve(address _spender, TRANSACTION[] calldata _transactions)
        external
        virtual
        override
    {
        for (uint256 i = 0; i < _transactions.length; i++) {
            require(
                msg.sender ==
                    classes[_transactions[i].classId]
                        .nonces[_transactions[i].nonceId]
                        .owner,
                "only owner can approve the transfer"
            );
            classes[_transactions[i].classId]
                .nonces[_transactions[i].nonceId]
                .allowances[msg.sender][_spender] = _transactions[i]._amount;
        }
    }

    function setApprovalFor(
        address operator,
        bool approved
    ) public virtual override {
        // TODO: implementing internal function for setting approval.
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalFor(msg.sender, operator, approved);
    }

    // READABLES 
    function totalSupply(uint256 classId, uint256 nonceId)
        public
        view
        override
        returns (uint256)
    {
        return (activeSupply(classId, nonceId) +
            burnedSupply(classId, nonceId) +
            redeemedSupply(classId, nonceId)
            );
    }

    function activeSupply(uint256 classId, uint256 nonceId)
        public
        view
        override
        returns (uint256)
    {
        return classes[classId].nonces[nonceId]._activeSupply;
    }

    function burnedSupply(uint256 classId, uint256 nonceId)
        public
        view
        override
        returns (uint256)
    {
        return classes[classId].nonces[nonceId]._burnedSupply;
    }

    function redeemedSupply(uint256 classId, uint256 nonceId)
        public
        view
        override
        returns (uint256)
    {
        return classes[classId].nonces[nonceId]._redeemedSupply;
    }

    function balanceOf(
        address account,
        uint256 classId,
        uint256 nonceId
    ) public view override returns (uint256) {
        require(
            account != address(0),
            "ERC3475: balance query for the zero address"
        );
        return classes[classId].nonces[nonceId].balances[account];
    }

    /**
    @dev here the classValues are stored in the single array as being described on the 
    
     */
    function classValues(uint256 classId)
        public
        view
        override
        returns (uint256[] memory)
    {
        return classes[classId]._values;
    }

    function nonceValues(uint256 classId, uint256 nonceId)
        public
        view
        override
        returns (uint256[] memory)
    {
        return classes[classId].nonces[nonceId]._values;
    }

    function classMetadata() 
    external 
    view 
    override 
    returns (METADATA[] memory) {
        return (_classMetadata);
    }

    function nonceMetadata(uint256 classId)
        external
        view
        override
        returns (METADATA[] memory) {
        return (classes[classId]._nonceMetadata);
    }

    /**
     * @notice ProgressAchieved and progressRemaining is abstract, here for the example we are giving time passed and time remaining.
     */
    function getProgress(uint256 classId, uint256 nonceId)
        public
        view
        override
        returns (uint256 progressAchieved, uint256 progressRemaining)
    {
        uint256 issuanceDate = classes[classId].nonces[nonceId]._values[0];
        uint256 maturityDate = issuanceDate + classes[classId]._values[5];        
        progressAchieved = block.timestamp - issuanceDate;
        progressRemaining = block.timestamp < maturityDate
            ? maturityDate - block.timestamp
            : 0;
    }

    function allowance(
        address owner,
        address spender,
        uint256 classId,
        uint256 nonceId
    ) public view virtual override returns (uint256) {
        require(
            owner == classes[classId].nonces[nonceId].owner,
            "only  the owner can get allowance"
        );
        return classes[classId].nonces[nonceId].allowances[owner][spender];
    }

    function isApprovedFor(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
        //require(owner == classes[classId].) TODO: generally this is the function implemented by the bank contract for allowing the approval for the whole class.
        return operatorApprovals[owner][operator];
    }

  

    function _transferFrom(
        address _from,
        address _to,
        IERC3475.TRANSACTION calldata _transaction
    ) private {

        require(
            classes[_transaction.classId]
                .nonces[_transaction.nonceId]
                .balances[_from] >= _transaction._amount,
            "ERC3475: not enough bond to transfer"
        );
        //transfer balance        
        classes[_transaction.classId].nonces[_transaction.nonceId].balances[_from] -=
        _transaction._amount;
        classes[_transaction.classId].nonces[_transaction.nonceId].balances[_to] +=
        _transaction._amount;    
    }

      function _transferAllowanceFrom(
        address _operator,
        address _from,
        address _to,
        IERC3475.TRANSACTION calldata _transaction
    ) private {
    
        require(
            classes[_transaction.classId]
                .nonces[_transaction.nonceId]
                .balances[_from] >= _transaction._amount,
            "ERC3475: not allowed amount"
        );

        classes[_transaction.classId]
            .nonces[_transaction.nonceId]
            .allowances[_from][_operator] -= _transaction._amount;

        //transfer balance        
        classes[_transaction.classId].nonces[_transaction.nonceId].balances[_from] -=
        _transaction._amount;
        classes[_transaction.classId].nonces[_transaction.nonceId].balances[_to] +=
        _transaction._amount;    

        
    }

    function _issue(
        address _to, 
        IERC3475.TRANSACTION calldata _transaction
        ) private
    {
        classes[_transaction.classId].nonces[_transaction.nonceId].balances[_to] +=
        _transaction._amount;

        classes[_transaction.classId].nonces[_transaction.nonceId]._activeSupply +=
        _transaction._amount;
    }


    function _redeem(address _from, IERC3475.TRANSACTION calldata _transaction)
        private
    {
        require(
            classes[_transaction.classId].nonces[_transaction.nonceId].balances[
                _from
            ] >= _transaction._amount
        );
        classes[_transaction.classId].nonces[_transaction.nonceId].balances[_from] -= 
        _transaction._amount;
        classes[_transaction.classId].nonces[_transaction.nonceId]._activeSupply -= 
        _transaction._amount;
        classes[_transaction.classId].nonces[_transaction.nonceId]._redeemedSupply += 
        _transaction._amount;
    }


    function _burn(address _from, IERC3475.TRANSACTION calldata _transaction)
        private
    {
        require(
            classes[_transaction.classId].nonces[_transaction.nonceId].balances[
                _from
            ] >= _transaction._amount
        );
        classes[_transaction.classId].nonces[_transaction.nonceId].balances[_from] -= 
        _transaction._amount;
        classes[_transaction.classId].nonces[_transaction.nonceId]._activeSupply -= 
        _transaction._amount;
        classes[_transaction.classId].nonces[_transaction.nonceId]._burnedSupply += 
        _transaction._amount;
    }

}
