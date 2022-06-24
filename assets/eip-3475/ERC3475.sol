// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;


import "./IERC3475.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC3475 is IERC3475, Ownable {
    /** 
    * @notice this Struct is representing the Nonce properties as an object
    */
    struct Nonce {
        mapping(uint256 => IERC3475.Values) _value;  

        // stores the values corresponding to the dates (issuance and maturity date).
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;

        // supplies of this nonce
        uint256 _activeSupply;
        uint256 _burnedSupply;
        uint256 _redeemedSupply;
    }

    /**
     * @notice this Struct is representing the Class properties as an object
     *         and can be retrieve by the classId
     */
    struct Class {
        mapping(uint256 => IERC3475.Values) _value;    

        mapping(uint256 => IERC3475.Metadata) _nonceMetadata;    
        mapping(uint256 => Nonce) nonces;        


        _classMetadata[1].title = "symbol";
        _classMetadata[1].types = "string";
        _classMetadata[1].description = "symbol of the class";
        classes[1]._value[0].stringValue = "DBIT Fix 6M";


        // define "period of the class";
        _classMetadata[5].title = "period";
        _classMetadata[5].types = "int";
        _classMetadata[5].description = "details about issuance and redemption time";
        // define the maturity time period  (for the test class).
        classes[0]._value[5].uintValue = 10;
        classes[1]._value[5].uintValue = 1;

        // write the time of maturity to nonce values, in other implementation, a create nonce function can be added
        classes[0].nonces[0]._value[0].uintValue = block.timestamp + 180 days;
        classes[0].nonces[1]._value[0].uintValue = block.timestamp + 181 days;
        classes[0].nonces[2]._value[0].uintValue = block.timestamp + 182 days;

        // test for review the instantaneous class
        classes[1].nonces[0]._value[0].uintValue = block.timestamp + 1;
        classes[1].nonces[1]._value[0].uintValue = block.timestamp + 2;
        classes[1].nonces[2]._value[0].uintValue = block.timestamp + 3;

        // defining the value status 
        classes[0].nonces[0]._value[0].boolValue = true;
        classes[0].nonces[1]._value[0].boolValue = true;
        classes[0].nonces[2]._value[0].boolValue = true;


        // define "maturity of the nonce";        
        classes[0]._nonceMetadata[0].title = "maturity";
        classes[0]._nonceMetadata[0].description = "maturity date in integer";

        classes[1]._nonceMetadata[0].title = "maturity";
        classes[1]._nonceMetadata[0].description = "maturity date in integer";


       


    }

    // WRITABLE
    function transferFrom(
        address _from,
        address _to,
        Transaction[] calldata _transactions
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
        Transaction[] calldata _transactions
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

    function issue(address _to, Transaction[] calldata _transactions)
        external
        virtual
        override
    {
        uint256 len = _transactions.length;

        for (uint256 i = 0; i < len; i++) {
            require(
                _to != address(0),
                "ERC3475: can't transfer to the zero address"
            );
        virtual
        override
    {
        for (uint256 i = 0; i < _transactions.length; i++) {
           
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
 
    function classMetadata(uint256 metadataId) 
    external 
    view 
    override 
    returns (Metadata memory) {
        return (_classMetadata[metadataId]);
    }

    function nonceMetadata(uint256 classId, uint256 metadataId)
        external
        view
        override
        returns (Metadata memory) {
        return (classes[classId]._nonceMetadata[metadataId]);
    }

    function classValues(uint256 classId, uint256 metadataId) 
    external 
    view 
    override 
    returns (Values memory) {
        return (classes[classId]._value[metadataId]);
    }

    function nonceValues(uint256 classId, uint256 nonceId, uint256 metadataId)
        external
        view
        override
        returns (Values memory) {
        return (classes[classId].nonces[nonceId]._value[metadataId]);
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

        uint256 issuanceDate = classes[classId].nonces[nonceId]._value[0].uintValue;
        uint256 maturityDate = issuanceDate + classes[classId].nonces[nonceId]._value[5].uintValue;   
        // check whether the bond is being already initialized: 
             
        progressAchieved = block.timestamp - issuanceDate;
        progressRemaining = block.timestamp < maturityDate
            ? maturityDate - block.timestamp
            : 0;
    }

    function allowance(
        address _owner,
        address spender,
        uint256 classId,
        uint256 nonceId
    ) public view virtual override returns (uint256) {
        return classes[classId].nonces[nonceId].allowances[_owner][spender];
    }

    function isApprovedFor(
        address _owner,
        address operator
    ) public view virtual override returns (bool) {
        return operatorApprovals[_owner][operator];
    }

  

    function _transferFrom(
        address _from,
        address _to,
        IERC3475.Transaction calldata _transaction
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
        IERC3475.Transaction calldata _transaction
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
        IERC3475.Transaction calldata _transaction
        ) private
    {
        classes[_transaction.classId].nonces[_transaction.nonceId].balances[_to] +=
        _transaction._amount;

        classes[_transaction.classId].nonces[_transaction.nonceId]._activeSupply +=
        _transaction._amount;
    }


    function _redeem(address _from, IERC3475.Transaction calldata _transaction)
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

    function _burn(address _from, IERC3475.Transaction calldata _transaction)
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
}
