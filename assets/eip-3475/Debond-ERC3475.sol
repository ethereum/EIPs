// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// @dev install the dependencies 
// npm i debond-erc3475-contracts.

import "debond-erc3475-contracts/interfaces/IDebondBond.sol";
import "debond-erc3475-contracts/interfaces/IRedeemableBondCalculator.sol";
import "debond-governance-contracts/utils/GovernanceOwnable.sol";

contract DebondERC3475 is IDebondBond, GovernanceOwnable {
    address bankAddress;    
    /**
    * @notice this Struct is representing the Nonce properties as an object
    *         and can be retrieved by the nonceId (within a class)
    */
    struct Nonce {
        uint256 id;
        bool exists;
        uint256 _activeSupply;
        uint256 _burnedSupply;
        uint256 _redeemedSupply;
        uint256 classLiquidity;
        uint256[] values;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
    }
    
    /**
    * @notice this Struct is representing the Class properties as an object
    *         and can be retrieved by the classId
    */
    struct Class {
        uint256 id;
        bool exists;
        string symbol;
        uint256[] values;
        uint256 liquidity;
        mapping(address => mapping(uint256 => bool)) noncesPerAddress;
        mapping(address => uint256[]) noncesPerAddressArray;
        mapping(address => mapping(address => bool)) operatorApprovals;
        uint256[] nonceIds;
        mapping(uint256 => Nonce) nonces; // from nonceId given
        uint256 lastNonceIdCreated;
        uint256 lastNonceIdCreatedTimestamp;
    }

    mapping(uint256 => Class) internal classes; // from classId given
    string[] public classInfoDescriptions; // mapping with class.infos
    string[] public nonceInfoDescriptions; // mapping with nonce.infos
    mapping(address => mapping(uint256 => bool)) classesPerHolder;
    mapping(address => uint256[]) public classesPerHolderArray;
    
    constructor(address _governanceAddress) GovernanceOwnable(_governanceAddress) {}
   
    modifier onlyBank() {
        require(msg.sender == bankAddress, "DebondERC3475 Error: Not authorized");
        _;
    }

    function setBankAddress(address _bankAddress) onlyGovernance external {
        require(_bankAddress != address(0), "DebondERC3475 Error: Address given is address(0)");
        bankAddress = _bankAddress;
    }
    
    // WRITEABLES
    function issue(address to, Transaction[] calldata transactions) external override onlyBank {
        for (uint i; i < transactions.length; i++) {
            uint classId = transactions[i].classId;
            uint nonceId = transactions[i].nonceId;
            uint amount = transactions[i]._amount;
            require(classes[classId].exists, "ERC3475: only issue bond that has been created");
            require(classes[classId].nonces[nonceId].exists, "ERC-3475: nonceId given not found!");
            require(to != address(0), "ERC3475: can't transfer to the zero address");
            _issue(to, classId, nonceId, amount);

            if (!classesPerHolder[to][classId]) {
                classesPerHolderArray[to].push(classId);
                classesPerHolder[to][classId] = true;
            }

            Class storage class = classes[classId];
            class.liquidity += amount;

            if (!class.noncesPerAddress[to][nonceId]) {
                class.noncesPerAddressArray[to].push(nonceId);
                class.noncesPerAddress[to][nonceId] = true;
            }

            Nonce storage nonce = class.nonces[nonceId];
            nonce.classLiquidity = class.liquidity + amount;
        }
        emit Issue(msg.sender, to, transactions);
    }

    function createClass(uint256 classId, string calldata _symbol, uint256[] calldata values) external onlyBank {
        require(!classExists(classId), "ERC3475: cannot create a class that already exists");
        Class storage class = classes[classId];
        class.id = classId;
        class.exists = true;
        class.symbol = _symbol;
        class.values = values;
    }

    function updateLastNonce(uint classId, uint nonceId, uint createdAt) external onlyBank {
        Class storage class = classes[classId];
        require(class.exists, "Debond Data: class id given not found");
        class.lastNonceIdCreated = nonceId;
        class.lastNonceIdCreatedTimestamp = createdAt;
    }

    function createNonce(uint256 classId, uint256 nonceId, uint256[] calldata values) external onlyBank {
        require(classExists(classId), "ERC3475: only issue bond that has been created");
        Class storage class = classes[classId];
        Nonce storage nonce = class.nonces[nonceId];
        require(!nonce.exists, "Error ERC-3475: nonceId exists!");
        nonce.id = nonceId;
        nonce.exists = true;
        nonce.values = values;
    }

    function getLastNonceCreated(uint classId) external view returns (uint nonceId, uint createdAt) {
        Class storage class = classes[classId];
        require(class.exists, "Debond Data: class id given not found");
        nonceId = class.lastNonceIdCreated;
        createdAt = class.lastNonceIdCreatedTimestamp;
        return (nonceId, createdAt);
    }

    function getNoncesPerAddress(address addr, uint256 classId) public view returns (uint256[] memory) {
        return classes[classId].noncesPerAddressArray[addr];
    }

    function batchActiveSupply(uint256 classId) public view returns (uint256) {
        uint256 _batchActiveSupply;
        uint256[] memory nonces = classes[classId].nonceIds;   
        // _lastBondNonces can be recovered from the last message of the nonceId
        for (uint256 i = 0; i <= nonces.length; i++) {
            _batchActiveSupply += activeSupply(classId, nonces[i]);
        }
        return _batchActiveSupply;
    }

    function batchBurnedSupply(uint256 classId) public view returns (uint256) {
        uint256 _batchBurnedSupply;
        uint256[] memory nonces = classes[classId].nonceIds;
        for (uint256 i = 0; i <= nonces.length; i++) {
            _batchBurnedSupply += burnedSupply(classId, nonces[i]);
        }
        return _batchBurnedSupply;
    }

    function batchRedeemedSupply(uint256 classId) public view returns (uint256) {
        uint256 _batchRedeemedSupply;
        uint256[] memory nonces = classes[classId].nonceIds;
        for (uint256 i = 0; i <= nonces.length; i++) {
            _batchRedeemedSupply += redeemedSupply(classId, nonces[i]);
        }
        return _batchRedeemedSupply;
    }

    function batchTotalSupply(uint256 classId) public view returns (uint256) {
        uint256 _batchTotalSupply;
        uint256[] memory nonces = classes[classId].nonceIds;
        for (uint256 i = 0; i <= nonces.length; i++) {
            _batchTotalSupply += totalSupply(classId, nonces[i]);
        }
        return _batchTotalSupply;
    }

    function transferFrom(address from, address to, Transaction[] calldata transactions) public virtual override {
        for (uint i; i < transactions.length; i++) {
            uint classId = transactions[i].classId;
            uint nonceId = transactions[i].nonceId;
            uint amount = transactions[i]._amount;
            require(msg.sender == from || isApprovedFor(from, msg.sender, classId), "ERC3475: caller is not owner nor approved");
            _transferFrom(from, to, classId, nonceId, amount);
        }
        emit Transfer(msg.sender, from, to, transactions);
    }

    function getProgress(uint256 classId, uint256 nonceId) public view returns (uint256 progressAchieved, uint256 progressRemaining) {
        return IRedeemableBondCalculator(bankAddress).getProgress(classId, nonceId);
    }

    function redeem(address from, Transaction[] calldata transactions) external override onlyBank {
        for (uint i; i < transactions.length; i++) {
            uint classId = transactions[i].classId;
            uint nonceId = transactions[i].nonceId;
            uint amount = transactions[i]._amount;
            require(classes[classId].nonces[nonceId].exists, "ERC3475: given Nonce doesn't exist");
            require(from != address(0), "ERC3475: can't transfer to the zero address");
            (, uint256 progressRemaining) = getProgress(classId, nonceId);
            require(progressRemaining == 0, "Bond is not redeemable");
            _redeem(from, classId, nonceId, amount);
        }
        emit Redeem(msg.sender, from, transactions);
    }

    function burn(address from, Transaction[] calldata transactions) external override onlyBank {
        require(from != address(0), "ERC3475: can't transfer to the zero address");
        for (uint i; i < transactions.length; i++) {
            uint classId = transactions[i].classId;
            uint nonceId = transactions[i].nonceId;
            uint amount = transactions[i]._amount;
            _burn(from, classId, nonceId, amount);
        }
        emit Burn(msg.sender, from, transactions);
    }

    function approve(address spender, Transaction[] calldata transactions) external override {
        for (uint i; i < transactions.length; i++) {
            uint classId = transactions[i].classId;
            uint nonceId = transactions[i].nonceId;
            uint amount = transactions[i]._amount;
            classes[classId].nonces[nonceId].allowances[msg.sender][spender] = amount;
        }
    }

    function setApprovalFor(address operator, uint256 classId, bool approved) public override {
        classes[classId].operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalFor(msg.sender, operator, classId, approved);
    }  
    
    // READABLES
    function classExists(uint256 classId) public view returns (bool) {
        return classes[classId].exists;
    }

    function nonceExists(uint256 classId, uint256 nonceId) public view returns (bool) {
        return classes[classId].nonces[nonceId].exists;
    }

    function classLiquidity(uint256 classId) external view returns (uint256) {
        return classes[classId].liquidity;
    }

    function classLiquidityAtNonce(uint256 classId, uint256 nonceId) external view returns (uint256) {
        require(nonceExists(classId, nonceId), "DebondERC3475 Error: nonce not found");
        return classes[classId].nonces[nonceId].classLiquidity;
    }

    function totalSupply(uint256 classId, uint256 nonceId) public override view returns (uint256) {
        return classes[classId].nonces[nonceId]._activeSupply + classes[classId].nonces[nonceId]._redeemedSupply;
    }

    function activeSupply(uint256 classId, uint256 nonceId) public override view returns (uint256) {
        return classes[classId].nonces[nonceId]._activeSupply;
    }

    function burnedSupply(uint256 classId, uint256 nonceId) public override view returns (uint256) {
        return classes[classId].nonces[nonceId]._burnedSupply;
    }

    function redeemedSupply(uint256 classId, uint256 nonceId) public override view returns (uint256) {
        return classes[classId].nonces[nonceId]._burnedSupply;
    }

    function balanceOf(address account, uint256 classId, uint256 nonceId) public override view returns (uint256) {
        require(account != address(0), "ERC3475: balance query for the zero address");
        return classes[classId].nonces[nonceId].balances[account];
    }

    function classValues(uint256 classId) public view override returns (uint256[] memory) {
        return classes[classId].values;
    }

    function nonceValues(uint256 classId, uint256 nonceId) public view override returns (uint256[] memory) {
        return classes[classId].nonces[nonceId].values;
    }

    function classMetadata() external view returns (Metadata[] memory m) {
        string[] memory s = new string[](1);
        m[0] = Metadata("", "", "", s);
    }

    function nonceMetadata(uint256 classId) external view returns (Metadata[] memory m) {
        string[] memory s = new string[](1);
        m[0] = Metadata("", "", "", s);
    }

    function allowance(address owner, address spender, uint256 classId, uint256 nonceId) external view returns (uint256) {
        return classes[classId].nonces[nonceId].allowances[owner][spender];
    }

    function isApprovedFor(address owner, address operator, uint256 classId) public view virtual override returns (bool) {
        return classes[classId].operatorApprovals[owner][operator];
    }
    
    // INTERNALS
    function _transferFrom(address from, address to, uint256 classId, uint256 nonceId, uint256 amount) internal {
        require(from != address(0), "ERC3475: can't transfer from the zero address");
        require(to != address(0), "ERC3475: can't transfer to the zero address");
        require(classes[classId].nonces[nonceId].balances[from] >= amount, "ERC3475: not enough bond to transfer");
        _transfer(from, to, classId, nonceId, amount);
    }

    function _transfer(address from, address to, uint256 classId, uint256 nonceId, uint256 amount) internal {
        require(from != to, "ERC3475: can't transfer to the same address");
        classes[classId].nonces[nonceId].balances[from] -= amount;
        classes[classId].nonces[nonceId].balances[to] += amount;
    }

    function _issue(address to, uint256 classId, uint256 nonceId, uint256 amount) internal {
        classes[classId].nonces[nonceId].balances[to] += amount;
        classes[classId].nonces[nonceId]._activeSupply += amount;
    }

    function _redeem(address from, uint256 classId, uint256 nonceId, uint256 amount) internal {
        require(classes[classId].nonces[nonceId].balances[from] >= amount);
        classes[classId].nonces[nonceId].balances[from] -= amount;
        classes[classId].nonces[nonceId]._activeSupply -= amount;
        classes[classId].nonces[nonceId]._redeemedSupply += amount;
    }

    function _burn(address from, uint256 classId, uint256 nonceId, uint256 amount) internal {
        require(classes[classId].nonces[nonceId].balances[from] >= amount);
        classes[classId].nonces[nonceId].balances[from] -= amount;
        classes[classId].nonces[nonceId]._activeSupply -= amount;
        classes[classId].nonces[nonceId]._burnedSupply += amount;
    }    
}
