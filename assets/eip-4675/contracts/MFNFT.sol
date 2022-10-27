// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./interface/IMFNFT.sol";
import "./interface/IERC721.sol";
import "./math/SafeMath.sol";
import "./helper/Verifier.sol";

/**
 * @title TWIG_FNFT Contract
 */
contract MFNFT is IMFNFT, Verifier {
    using SafeMath for uint256;

    mapping(uint256 => mapping(address => uint256)) private _balances;

    mapping(uint256 => mapping(address => mapping(address => uint256)))
        private _allowed;

    // uint256 private _totalSupply;
    mapping(uint256 => uint256) _totalSupply;

    // NFT Contract Address
    // address private _parentToken;
    mapping(uint256 => address) _parentToken;

    // NFT ID of NFT(RFT) - TokenId
    // uint256 private _parentTokenId;
    mapping(uint256 => uint256) _parentTokenId;

    //
    mapping(address => mapping(uint256 => uint256)) private _Ids;

    // Scalar value to distinguish fractionalized NFT
    uint256 public _id;

    // Admin Address to Set the Parent NFT
    address private _admin;

    // Event emitted when token is added
    event TokenAddition(
        address indexed token,
        uint256 tokenId,
        uint256 _id,
        uint256 totalSupply
    );

    constructor() {
        _admin = msg.sender;
    }

    /**
     * @dev onlyAdmin prohibits function calls arbitrary msg.sender
     * except _admin
     */
    modifier onlyAdmin() {
        require(msg.sender == _admin);
        _;
    }

    /**
     * @dev Mandatory function to receive NFT as a contract(CA)
     * @return Bytes4 which is the selector of this function
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev (ERC165) Determines if this contract supports Re-FT(ERC1633).
     * @param interfaceID The bytes4 to query if it matches with the contract interface id.
     */
    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool)
    {
        return
            interfaceID == this.supportsInterface.selector || // ERC165
            interfaceID == this.parentToken.selector || // parentToken()
            interfaceID == this.parentTokenId.selector || // parentTokenId()
            interfaceID ==
            this.parentToken.selector ^ this.parentTokenId.selector; // RFT
    }

    /**
     * @dev Sets the Address of NFT Contract Address & NFT Token ID
     * @param parentNFTContractAddress The address NFT Contract address.
     * @param parentNFTTokenId The token id of NFT.
     */
    function setParentNFT(
        address parentNFTContractAddress,
        uint256 parentNFTTokenId,
        uint256 totalSupply
    ) public onlyAdmin {
        require(
            parentNFTContractAddress != address(0),
            "MFNFT::setParentNFT: Parent NFT Contract should not be zero"
        );
        require(
            getTokenId(parentNFTContractAddress, parentNFTTokenId) == 0,
            "MFNFT::setParentNFT: Already owned(fractionalized) by this contract"
        );

        verifyOwnership(parentNFTContractAddress, parentNFTTokenId);

        _id++;

        _Ids[parentNFTContractAddress][parentNFTTokenId] = _id;

        _parentToken[_id] = parentNFTContractAddress;
        _parentTokenId[_id] = parentNFTTokenId;

        _totalSupply[_id] = totalSupply;
        _balances[_id][msg.sender] = totalSupply;

        emit TokenAddition(
            parentNFTContractAddress,
            parentNFTTokenId,
            _id,
            totalSupply
        );
    }

    /**
     * @dev Returns the tokenId of with the given NFT information
     * @return An uint256 value representing the tokenId of given NFT
     */
    function getTokenId(address token, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _Ids[token][tokenId];
    }

    /**
     * @dev Returns if the NFT is owned(fractionalized) by this contract.
     * @return An bool representing whether the NFT is fractionalized by this contract
     */
    function isRegistered(address token, uint256 tokenId) public view returns (bool) {
        return (_Ids[token][tokenId] != 0);
    }

    /**
     * @dev Returns the Address of Parent Token Address
     * @return An Address representing the address of NFT Contract this Re-FT is pointing to.
     */
    function parentToken(uint256 tokenId) external view returns (address) {
        return _parentToken[tokenId];
    }

    /**
     * @dev Returns the Token ID of NFT
     * @return An uint256 representing the token id of the NFT this Re-FT is pointing to.
     */
    function parentTokenId(uint256 tokenId) external view returns (uint256) {
        return _parentTokenId[tokenId];
    }

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        return _totalSupply[tokenId];
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner, uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        return _balances[tokenId][owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address owner,
        address spender,
        uint256 tokenId
    ) public view override returns (uint256) {
        return _allowed[tokenId][owner][spender];
    }

    /**
     * @dev Transfer token for a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(
        address to,
        uint256 tokenId,
        uint256 value
    ) public override returns (bool) {
        _transfer(msg.sender, to, tokenId, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(
        address spender,
        uint256 tokenId,
        uint256 value
    ) public override returns (bool) {
        require(spender != address(0));

        _allowed[tokenId][msg.sender][spender] = value;
        emit Approval(msg.sender, spender, tokenId, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) public override returns (bool) {
        _allowed[tokenId][from][msg.sender] = _allowed[tokenId][from][
            msg.sender
        ].sub(value);
        _transfer(from, to, tokenId, value);
        emit Approval(
            from,
            msg.sender,
            tokenId,
            _allowed[tokenId][from][msg.sender]
        );
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(
        address spender,
        uint256 tokenId,
        uint256 addedValue
    ) public returns (bool) {
        require(spender != address(0));

        _allowed[tokenId][msg.sender][spender] = _allowed[tokenId][msg.sender][
            spender
        ].add(addedValue);

        emit Approval(
            msg.sender,
            spender,
            tokenId,
            _allowed[tokenId][msg.sender][spender]
        );
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(
        address spender,
        uint256 tokenId,
        uint256 subtractedValue
    ) public returns (bool) {
        require(spender != address(0));

        _allowed[tokenId][msg.sender][spender] = _allowed[tokenId][msg.sender][
            spender
        ].sub(subtractedValue);
        emit Approval(
            msg.sender,
            spender,
            tokenId,
            _allowed[tokenId][msg.sender][spender]
        );
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal {
        require(to != address(0));

        _balances[tokenId][from] = _balances[tokenId][from].sub(value);
        _balances[tokenId][to] = _balances[tokenId][to].add(value);

        emit Transfer(from, to, tokenId, value);
    }
}
