// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libraries/OmniverseProtocolHelper.sol";
import "./interfaces/IERC6358NonFungible.sol";

/**
* @notice Non-Fungible token data structure, from which the field `payload` in `ERC6358TransactionData` will be encoded
*
* @member op: The operation type
* NOTE op: 0-31 are reserved values, 32-255 are custom values
*           op: 0 - omniverse account `from` transfers the token with id `tokenId` to omniverse account `exData`, `from` have the token with id `tokenId`
*           op: 1 - omniverse account `from` mints the token with id `tokenId` to omniverse account `exData`
*           op: 2 - omniverse account `from` burns the token with id `tokenId` from omniverse account `exData`, `exData` MUST have the token with id `tokenId`
* @member exData: The operation data. This sector could be empty and is determined by `op`. For example: 
            when `op` is 0 and 1, `exData` stores the omniverse account that receives.
            when `op` is 2, `exData` is empty.
* @member tokenId: The token id of the non-fungible token being operated
 */
struct NonFungible {
    uint8 op;
    bytes exData;
    uint256 tokenId;
}

/**
 * @notice Implementation of the {IERC6358NonFungible} interface
 */
contract ERC6358NonFungibleExample is Ownable, IERC6358NonFungible, IERC721, IERC721Metadata {
    using Strings for uint256;

    uint8 constant TRANSFER = 0;
    uint8 constant MINT = 1;
    uint8 constant BURN = 2;

    /** @notice Used to index a delayed transaction
     * sender: The account which sent the transaction
     * nonce: The nonce of the delayed transaction
     */
    struct DelayedTx {
        bytes sender;
        uint256 nonce;
    }

    /**
     * @notice The member information
     * chainId: The chain which the member belongs to
     * contractAddr: The contract address on the member chain
     */
    struct Member {
        uint32 chainId;
        bytes contractAddr;
    }

    // Token name
    string private tokenName;
    // Token symbol
    string private tokenSymbol;
    // Base URI
    string public baseURI;
    // Chain id used to distinguish different chains
    uint32 chainId;
    // O-transaction cooling down time
    uint256 public cdTime;
    // Omniverse accounts record
    mapping(bytes => RecordedCertificate) transactionRecorder;
    // Transactions to be executed
    mapping(bytes => OmniverseTx) public transactionCache;

    // All information of chains on which the token is deployed
    Member[] members;
    // Token owners
    mapping(uint256 => bytes) omniverseOwners;
    // Omniverse balances
    mapping(bytes => uint256) omniverseBalances;
    // Delay-executing transactions
    DelayedTx[] delayedTxs;
    // Account map from evm address to public key
    mapping(address => bytes) accountsMap;

    event OmniverseTokenTransfer(bytes from, bytes to, uint256 value);

    /**
     * @notice Initiates the contract
     * @param _chainId The chain which the contract is deployed on
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     */
    constructor(uint32 _chainId, string memory _name, string memory _symbol) {
        chainId = _chainId;
        tokenName = _name;
        tokenSymbol = _symbol;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @notice See {IERC6358NonFungible-sendOmniverseTransaction}
     * Send an omniverse transaction
     */
    function sendOmniverseTransaction(ERC6358TransactionData calldata _data) external override {
        _omniverseTransaction(_data);
    }

    /**
     * @notice See {IERC6358NonFungible-triggerExecution}
     */
    function triggerExecution() external {
        require(delayedTxs.length > 0, "No delayed tx");

        OmniverseTx storage cache = transactionCache[delayedTxs[0].sender];
        require(cache.timestamp != 0, "Not cached");
        require(cache.txData.nonce == delayedTxs[0].nonce, "Nonce error");
        (ERC6358TransactionData storage txData, uint256 timestamp) = (cache.txData, cache.timestamp);
        require(block.timestamp >= timestamp + cdTime, "Not executable");
        delayedTxs[0] = delayedTxs[delayedTxs.length - 1];
        delayedTxs.pop();
        cache.timestamp = 0;
        // Add to transaction recorder
        RecordedCertificate storage rc = transactionRecorder[txData.from];
        rc.txList.push(cache);

        NonFungible memory nonFungible = decodeData(txData.payload);
        if (nonFungible.op == TRANSFER) {
            _omniverseTransfer(txData.from, nonFungible.exData, nonFungible.tokenId);
        }
        else if (nonFungible.op == MINT) {
            _checkOwner(txData.from);
            _omniverseMint(nonFungible.exData, nonFungible.tokenId);
        }
        else if (nonFungible.op == BURN) {
            _checkOwner(txData.from);
            _checkOmniverseBurn(nonFungible.exData, nonFungible.tokenId);
            _omniverseBurn(nonFungible.exData, nonFungible.tokenId);
        }
    }

    /**
     * @notice See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view returns (uint256 balance) {
        bytes storage pk = accountsMap[owner];
        if (pk.length == 0) {
            balance = 0;
        }
        else {
            balance = omniverseBalances[pk];
        }
    }

    /**
     * @notice See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner) {
        bytes memory ret = this.omniverseOwnerOf(tokenId);
        return OmniverseProtocolHelper.pkToAddress(ret);
    }

    /**
     * @notice See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external {

    }

    /**
     * @notice See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {

    }

    /**
     * @notice See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {

    }

    /**
     * @notice See {IERC721-approve}.
     */
    function approve(address /*to*/, uint256 /*tokenId*/) external {

    }

    /**
     * @notice See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address /*operator*/, bool /*_approved*/) external {

    }

    /**
     * @notice See {IERC721-getApproved}.
     */
    function getApproved(uint256 /*tokenId*/) external pure returns (address /*operator*/) {
        revert("Forbidden");
    }

    /**
     * @notice See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address /*owner*/, address /*operator*/) external pure returns (bool) {
        return false;
    }

    /**
     * @notice See {IERC721Metadata-name}.
     */
    function name() external view returns (string memory) {
        return tokenName;
    }

    /**
     * @notice See {IERC721Metadata-symbol}.
     */
    function symbol() external view returns (string memory) {
        return tokenSymbol;
    }

    /**
     * @notice See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        bytes memory ret = omniverseOwners[tokenId];
        require(keccak256(ret) != keccak256(bytes("")), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @notice Sets the base URI.
     */
    function setBaseURI(string calldata _baseURI) public {
        baseURI = _baseURI;
    }
    
    /**
     * @notice Check if the transaction can be executed successfully
     */
    function _checkExecution(ERC6358TransactionData memory txData) internal view {
        NonFungible memory nonFungible = decodeData(txData.payload);
        if (nonFungible.op == TRANSFER) {
            _checkOmniverseTransfer(txData.from, nonFungible.tokenId);
        }
        else if (nonFungible.op == MINT) {
            _checkOwner(txData.from);
            _checkOmniverseMint(nonFungible.tokenId);
        }
        else if (nonFungible.op == BURN) {
            _checkOwner(txData.from);
            _checkOmniverseBurn(nonFungible.exData, nonFungible.tokenId);
        }
        else {
            revert("OP code error");
        }
    }

    /**
     * @notice Returns the nearest exexutable delayed transaction info
     * or returns default if not found
     */
    function getExecutableDelayedTx() external view returns (DelayedTx memory ret) {
        if (delayedTxs.length > 0) {
            OmniverseTx storage cache = transactionCache[delayedTxs[0].sender];
            if (block.timestamp >= cache.timestamp + cdTime) {
                ret = delayedTxs[0];
            }
        }
    }

    /**
     * @notice Returns the count of delayed transactions
     */
    function getDelayedTxCount() external view returns (uint256) {
        return delayedTxs.length;
    }

    /**
     * @notice See {IERC6358NonFungible-omniverseBalanceOf}
     * Returns the omniverse balance of a user
     */
    function omniverseBalanceOf(bytes calldata _pk) external view override returns (uint256) {
        return omniverseBalances[_pk];
    }

    /**
     * @notice See {IERC6358NonFungible-omniverseOwnerOf}
     * Returns the owner of a token
     */
    function omniverseOwnerOf(uint256 _tokenId) external view returns (bytes memory) {
        bytes memory ret = omniverseOwners[_tokenId];
        require(keccak256(ret) != keccak256(bytes("")), "Token not exist");
        return ret;
    }

    /**
     * @notice Receive and check an omniverse transaction
     */
    function _omniverseTransaction(ERC6358TransactionData memory _data) internal {
        // Check if the tx initiateSC is correct
        bool found = false;
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i].chainId == _data.chainId) {
                require(keccak256(members[i].contractAddr) == keccak256(_data.initiateSC), "Wrong initiateSC");
                found = true;
            }
        }
        require(found, "Wrong initiateSC");

        // Check if the sender is honest
        // to be continued, we can use block list instead of `isMalicious`
        require(!isMalicious(_data.from), "User malicious");

        // Verify the signature
        VerifyResult verifyRet = OmniverseProtocolHelper.verifyTransaction(transactionRecorder[_data.from], _data);

        if (verifyRet == VerifyResult.Success) {
            // Check cache
            OmniverseTx storage cache = transactionCache[_data.from];
            require(cache.timestamp == 0, "Transaction cached");
            // Logic verification
            _checkExecution(_data);
            // Delays in executing
            cache.txData = _data;
            cache.timestamp = block.timestamp;
            delayedTxs.push(DelayedTx(_data.from, _data.nonce));
            if (_data.chainId == chainId) {
                emit TransactionSent(_data.from, _data.nonce);
            }
        }
        else if (verifyRet == VerifyResult.Duplicated) {
            emit TransactionExecuted(_data.from, _data.nonce);
        }
        else if (verifyRet == VerifyResult.Malicious) {
            // Slash
        }
    }

    /**
     * @notice Check if an omniverse transfer operation can be executed successfully
     */
    function _checkOmniverseTransfer(bytes memory _from, uint256 _tokenId) internal view {
        require(keccak256(this.omniverseOwnerOf(_tokenId)) == keccak256(_from), "Not owner");
    }

    /**
     * @notice Exucute an omniverse transfer operation
     */
    function _omniverseTransfer(bytes memory _from, bytes memory _to, uint256 _tokenId) internal {
        _checkOmniverseTransfer(_from, _tokenId);
        
        omniverseOwners[_tokenId] = _to;
        omniverseBalances[_from] -= 1;
        omniverseBalances[_to] += 1;

        emit OmniverseTokenTransfer(_from, _to, _tokenId);

        address fromAddr = OmniverseProtocolHelper.pkToAddress(_from);
        address toAddr = OmniverseProtocolHelper.pkToAddress(_to);
        accountsMap[toAddr] = _to;
        emit Transfer(fromAddr, toAddr, _tokenId);
    }
    
    /**
     * @notice Check if the public key is the owner
     */
    function _checkOwner(bytes memory _pk) internal view {
        address fromAddr = OmniverseProtocolHelper.pkToAddress(_pk);
        require(fromAddr == owner(), "Not owner");
    }

    /**
     * @notice Check if an omniverse mint operation can be executed successfully
     */
    function _checkOmniverseMint(uint256 _tokenId) internal view {
        require(keccak256(omniverseOwners[_tokenId]) == keccak256(""), "Token already exist");
    }

    /**
     * @notice Execute an omniverse mint operation
     */
    function _omniverseMint(bytes memory _to, uint256 _tokenId) internal {
        _checkOmniverseMint(_tokenId);

        omniverseOwners[_tokenId] = _to;
        omniverseBalances[_to] += 1;
        emit OmniverseTokenTransfer("", _to, _tokenId);

        address toAddr = OmniverseProtocolHelper.pkToAddress(_to);
        accountsMap[toAddr] = _to;
        emit Transfer(address(0), toAddr, _tokenId);
    }

    /**
     * @notice Check if an omniverse burn operation can be executed successfully
     */
    function _checkOmniverseBurn(bytes memory _from, uint256 _tokenId) internal view {
        require(keccak256(this.omniverseOwnerOf(_tokenId)) == keccak256(_from), "Not token owner");
    }

    /**
     * @notice Execute an omniverse burn operation
     */
    function _omniverseBurn(bytes memory _from, uint256 _tokenId) internal {
        delete omniverseOwners[_tokenId];
        omniverseBalances[_from] -= 1;
        emit OmniverseTokenTransfer(_from, "", _tokenId);

        address fromAddr = OmniverseProtocolHelper.pkToAddress(_from);
        emit Transfer(fromAddr, address(0), _tokenId);
    }

    /**
     * @notice Add new chain members to the token
     */
    function setMembers(Member[] calldata _members) external onlyOwner {
        for (uint256 i = 0; i < _members.length; i++) {
            if (i < members.length) {
                members[i] = _members[i];
            }
            else {
                members.push(_members[i]);
            }
        }

        for (uint256 i = _members.length; i < members.length; i++) {
            delete members[i];
        }
    }

    /**
     * @notice Returns chain members of the token
     */
    function getMembers() external view returns (Member[] memory) {
        return members;
    }

    /**
     * @notice See IERC6358NonFungible
     */
    function getTransactionCount(bytes memory _pk) external override view returns (uint256) {
        return transactionRecorder[_pk].txList.length;
    }

    /**
     * @notice See IERC6358NonFungible
     */
    function getTransactionData(bytes calldata _user, uint256 _nonce) external override view returns (ERC6358TransactionData memory txData, uint256 timestamp) {
        RecordedCertificate storage rc = transactionRecorder[_user];
        OmniverseTx storage omniTx = rc.txList[_nonce];
        txData = omniTx.txData;
        timestamp = omniTx.timestamp;
    }

    /**
     * @notice Set the cooling down time of an omniverse transaction
     */
    function setCoolingDownTime(uint256 _time) external {
        cdTime = _time;
    }

    /**
     * @notice Index the user is malicious or not
     */
    function isMalicious(bytes memory _pk) public view returns (bool) {
        RecordedCertificate storage rc = transactionRecorder[_pk];
        return (rc.evilTxList.length > 0);
    }

    /**
     * @notice See IERC6358NonFungible
     */
    function getChainId() external view returns (uint32) {
        return chainId;
    }

    /**
     * @notice Decode `_data` from bytes to Fungible
     */
    function decodeData(bytes memory _data) internal pure returns (NonFungible memory) {
        (uint8 op, bytes memory exData, uint256 tokenId) = abi.decode(_data, (uint8, bytes, uint256));
        return NonFungible(op, exData, tokenId);
    }

    /**
     * @notice See IERC6358Application
     */
    function getPayloadRawData(bytes memory _payload) external pure returns (bytes memory) {
        NonFungible memory nonFungible = decodeData(_payload);
        return abi.encodePacked(nonFungible.op, nonFungible.exData, uint128(nonFungible.tokenId));
    }
}