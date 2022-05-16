// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./IERC3475.sol";

contract ERC3475 is IERC3475 {

    /**
    * @notice this Struct is representing the Nonce properties as an object
    *         and can be retrieve by the nonceId (within a class)
    */
    struct Nonce {
        uint256 nonceId;
        bool exists;
        uint256 _activeSupply;
        uint256 _burnedSupply;
        uint256 _redeemedSupply;
        uint256[] infos;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
    }

    /**
    * @notice this Struct is representing the Class properties as an object
    *         and can be retrieve by the classId
    */
    struct Class {
        uint256 classId;
        bool exists;
        string symbol;
        uint256[] infos;
        mapping(address => mapping(address => bool)) operatorApprovals;
        mapping(uint256 => Nonce) nonces; // from nonceId given
    }

    mapping(uint256 => Class) internal classes; // from classId given
    string[] public classInfoDescriptions; // mapping with class.infos
    string[] public nonceInfoDescriptions; // mapping with nonce.infos

    /**
    * @notice Here the constructor is just to initialize a class and nonce,
    *         in practice you will have a function to create new class and nonce
    */
    constructor() {
        // creating class
        Class storage class = classes[0];
        class.classId = 0;
        class.exists = true;
        class.symbol = "DBIT";
        class.infos.push(0); classInfoDescriptions.push("informationA of class A");
        class.infos.push(1); classInfoDescriptions.push("informationB of class is of type B");
        class.infos.push(2); classInfoDescriptions.push("informationC is a perfect example");

        // creating nonce
        Nonce storage nonce = class.nonces[0];
        nonce.nonceId = 0;
        nonce.exists = true;
        nonce.infos.push(0); nonceInfoDescriptions.push("information nonce");
        nonce.infos.push(1); nonceInfoDescriptions.push("informationA of nonce important");
        nonce.infos.push(2); nonceInfoDescriptions.push("informationE");
    }


    // WRITE


    function transferFrom(address from, address to, uint256 classId, uint256 nonceId, uint256 amount) public virtual override {
        require(msg.sender == from || isApprovedFor(from, msg.sender, classId), "ERC3475: caller is not owner nor approved");
        _transferFrom(from, to, classId, nonceId, amount);
        emit Transfer(msg.sender, from, to, classId, nonceId, amount);
    }


    function issue(address to, uint256 classId, uint256 nonceId, uint256 amount) external virtual override {
        require(classes[classId].exists, "ERC3475: only issue bond that has been created");
        Class storage class = classes[classId];

        Nonce storage nonce = class.nonces[nonceId];
        require(nonceId == nonce.nonceId, "Error ERC-3475: nonceId given not found!");

        require(to != address(0), "ERC3475: can't transfer to the zero address");
        _issue(to, classId, nonceId, amount);
        emit Issue(msg.sender, to, classId, nonceId, amount);
    }


    function redeem(address from, uint256 classId, uint256 nonceId, uint256 amount) external virtual override {
        require(from != address(0), "ERC3475: can't transfer to the zero address");
        require(isRedeemable(classId, nonceId));
        _redeem(from, classId, nonceId, amount);
        emit Redeem(msg.sender, from, classId, nonceId, amount);
    }


    function burn(address from, uint256 classId, uint256 nonceId, uint256 amount) external virtual override {
        require(from != address(0), "ERC3475: can't transfer to the zero address");
        _burn(from, classId, nonceId, amount);
        emit Burn(msg.sender, from, classId, nonceId, amount);
    }


    function approve(address spender, uint256 classId, uint256 nonceId, uint256 amount) external virtual override {
        classes[classId].nonces[nonceId].allowances[msg.sender][spender] = amount;
    }


    function setApprovalFor(address operator, uint256 classId, bool approved) public virtual override {
        classes[classId].operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalFor(msg.sender, operator, classId, approved);
    }


    function batchApprove(address spender, uint256[] calldata classIds, uint256[] calldata nonceIds, uint256[] calldata amounts) external {
        require(classIds.length == nonceIds.length && classIds.length == amounts.length, "ERC3475 Input Error");
        for(uint256 i = 0; i < classIds.length; i++) {
            classes[classIds[i]].nonces[nonceIds[i]].allowances[msg.sender][spender] = amounts[i];
        }
    }
    // READS


    function totalSupply(uint256 classId, uint256 nonceId) public override view returns (uint256) {
        return classes[classId].nonces[nonceId]._activeSupply + classes[classId].nonces[nonceId]._redeemedSupply + classes[classId].nonces[nonceId]._burnedSupply;
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


    function symbol(uint256 classId) public view override returns (string memory) {
        Class storage class = classes[classId];
        return class.symbol;
    }


    function classInfos(uint256 classId) public view override returns (uint256[] memory) {
        return classes[classId].infos;
    }


    function nonceInfos(uint256 classId, uint256 nonceId) public view override returns (uint256[] memory) {
        return classes[classId].nonces[nonceId].infos;
    }

    function classInfoDescription(uint256 classInfo) external view returns (string memory) {
        return classInfoDescriptions[classInfo];
    }

    function nonceInfoDescription(uint256 nonceInfo) external view returns (string memory) {
        return nonceInfoDescriptions[nonceInfo];
    }


    function isRedeemable(uint256 classId, uint256 nonceId) public override view returns (bool) {
        return classes[classId].nonces[nonceId]._activeSupply > 0;
    }


    function allowance(address owner, address spender, uint256 classId, uint256 nonceId) external view returns (uint256) {
        return classes[classId].nonces[nonceId].allowances[owner][spender];
    }


    function isApprovedFor(address owner, address operator, uint256 classId) public view virtual override returns (bool) {
        return classes[classId].operatorApprovals[owner][operator];
    }

    function _transferFrom(address from, address to, uint256 classId, uint256 nonceId, uint256 amount) private {
        require(from != address(0), "ERC3475: can't transfer from the zero address");
        require(to != address(0), "ERC3475: can't transfer to the zero address");
        require(classes[classId].nonces[nonceId].balances[from] >= amount, "ERC3475: not enough bond to transfer");
        _transfer(from, to, classId, nonceId, amount);
    }

    function _transfer(address from, address to, uint256 classId, uint256 nonceId, uint256 amount) private {
        require(from != to, "ERC3475: can't transfer to the same address");
        classes[classId].nonces[nonceId].balances[from]-= amount;
        classes[classId].nonces[nonceId].balances[to] += amount;
    }

    function _issue(address to, uint256 classId, uint256 nonceId, uint256 amount) private {
        classes[classId].nonces[nonceId].balances[to] += amount;
        classes[classId].nonces[nonceId]._activeSupply += amount;
    }

    function _redeem(address from, uint256 classId, uint256 nonceId, uint256 amount) private {
        require(classes[classId].nonces[nonceId].balances[from] >= amount);
        classes[classId].nonces[nonceId].balances[from] -= amount;
        classes[classId].nonces[nonceId]._activeSupply -= amount;
        classes[classId].nonces[nonceId]._redeemedSupply += amount;
    }

    function _burn(address from, uint256 classId, uint256 nonceId, uint256 amount) private {
        require(classes[classId].nonces[nonceId].balances[from] >= amount);
        classes[classId].nonces[nonceId].balances[from] -= amount;
        classes[classId].nonces[nonceId]._activeSupply -= amount;
        classes[classId].nonces[nonceId]._burnedSupply += amount;
    }

}
